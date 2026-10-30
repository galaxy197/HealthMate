import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from import_usda_current import ROOT, SOURCES, convert, load_archive, nutrition, source_portion


def nutrient(key, amount, unit='g'):
    return {'nutrient': {'id': key, 'unitName': unit}, 'amount': amount}


def food():
    return {'fdcId': 123, 'description': 'Tomatoes, raw', 'dataType': 'Foundation',
            'publicationDate': '12/18/2025',
            'foodCategory': {'description': 'Vegetables and Vegetable Products'},
            'foodNutrients': [nutrient(2047, 20, 'kcal'), nutrient(1003, 1),
                              nutrient(1004, 0), nutrient(1005, 4)]}


class CurrentUsdaTest(unittest.TestCase):
    def test_energy_types_are_alternatives_with_explicit_precedence(self):
        row = {'foodNutrients': [nutrient(1008, 99, 'kcal'), nutrient(2047, 80, 'kcal'),
                                  nutrient(2048, 70, 'kcal')]}
        data, key = nutrition(row, 'foundation')
        self.assertEqual((data['kcalPer100g'], key), (70, 2048))
        self.assertEqual(nutrition(row, 'fndds')[0]['kcalPer100g'], 99)
        row['foodNutrients'].pop()
        self.assertEqual(nutrition(row, 'foundation')[1], 2047)

    def test_missing_values_and_wrong_units_do_not_become_zero(self):
        row = food()
        row['foodNutrients'][0] = nutrient(2047, 80, 'kJ')
        self.assertEqual(convert(row, 'foundation')[1], 'missing_core_nutrient')
        for bad in [None, -1, float('nan'), float('inf'), True, '1']:
            row = food()
            row['foodNutrients'][1]['amount'] = bad
            self.assertEqual(convert(row, 'foundation')[1], 'missing_core_nutrient')
        row = food()
        row['foodNutrients'][1]['nutrient']['unitName'] = 'mg'
        self.assertEqual(convert(row, 'foundation')[1], 'missing_core_nutrient')
        self.assertEqual(convert(food(), 'foundation')[0]['fatGPer100g'], 0)

    def test_conflicting_nutrients_fail_instead_of_picking_arbitrary_row(self):
        row = food()
        row['foodNutrients'].append(nutrient(1003, 99))
        with self.assertRaisesRegex(ValueError, 'Conflicting'):
            nutrition(row, 'foundation')

    def test_null_and_specialized_records_are_excluded(self):
        self.assertEqual(convert(None, 'foundation')[1], 'null_or_invalid_record')
        for name in ['Infant formula', 'Milk, human milk', 'Baby Toddler cereal', 'Oil as ingredient in food']:
            row = {**food(), 'description': name}
            self.assertEqual(convert(row, 'foundation')[1], 'outside_general_adult_catalog')

    def test_release_and_publication_are_separate_and_portions_are_not_guessed(self):
        result, error = convert(food(), 'foundation')
        self.assertIsNone(error)
        self.assertEqual(result['sourceDetails']['datasetRelease'], '2026-04-30')
        self.assertEqual(result['sourceDetails']['publicationDate'], '2025-12-18')
        self.assertIn('công bố 18/12/2025', result['sourceLabel'])
        self.assertNotIn('servingGrams', result)
        self.assertIn('Cà chua', result['name'])

    def test_foundation_portion_normalizes_source_amount(self):
        row = {'foodPortions': [{'id': 1, 'amount': 2, 'gramWeight': 33.9,
                                 'measureUnit': {'name': 'tablespoons'}}]}
        self.assertEqual(source_portion(row, 'foundation')['servingGrams'], 16.95)
        row['foodPortions'][0]['amount'] = 0
        self.assertEqual(source_portion(row, 'foundation'), {})

    def test_survey_portion_uses_description_and_not_numeric_modifier_code(self):
        row = {'foodPortions': [{'portionDescription': '1/2 cup', 'gramWeight': 60, 'modifier': '10205'}]}
        result = source_portion(row, 'fndds')
        self.assertEqual(result['servingGrams'], 120)
        self.assertEqual(result['portionSource']['amount'], .5)
        for label in ['Quantity not specified', 'Guideline amount per cup', '1/0 cup', '1 cup, with bone', 'RACC']:
            row['foodPortions'][0]['portionDescription'] = label
            self.assertEqual(source_portion(row, 'fndds'), {})

    def test_survey_mixed_food_never_claims_complete_ingredients_or_vegan(self):
        row = copy.deepcopy(food())
        row.update(dataType='Survey (FNDDS)', description='Beans, cooked, with butter')
        row['foodNutrients'][0] = nutrient(1008, 150, 'kcal')
        result, error = convert(row, 'fndds')
        self.assertIsNone(error)
        self.assertFalse(result['ingredientsKnown'])
        self.assertEqual(result['dietaryClass'], 'unknown')

    def test_archive_checksum_is_required_before_parsing(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fake.zip'
            path.write_bytes(b'not the reviewed official archive')
            with self.assertRaisesRegex(ValueError, 'reviewed official'):
                load_archive(path, SOURCES['foundation'])

    def test_generated_asset_matches_manifest_and_retains_historical_source_ids(self):
        path = ROOT / 'assets/nutrition/usda-current.json'
        payload = json.loads(path.read_text(encoding='utf-8'))
        report = json.loads((ROOT / 'data/food_catalog/usda-current-manifest.json').read_text(encoding='utf-8'))
        foods = payload['foods']
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), report['assetSha256'])
        self.assertEqual(len(foods), report['addedFoods'])
        self.assertEqual(len({f['fdcId'] for f in foods}), len(foods))
        historical = [f for name in ('vietnamese-foods.json', 'usda-sr-legacy.json')
                      for f in json.loads((path.parent / name).read_text(encoding='utf-8'))['foods']]
        self.assertFalse({f['id'] for f in foods} & {f['id'] for f in historical})
        self.assertEqual(len(foods) + len(historical), report['bundledTotal'])
        for kind, spec in report['sources'].items():
            self.assertEqual(spec['inputRecords'], spec['addedFoods'] + sum(spec['excluded'].values()))
        for row in foods:
            self.assertTrue(0 < len(row['name']) <= 100)
            self.assertLessEqual(len(row['sourceLabel']), 160)
            self.assertEqual(row['sourceDetails']['description'], row['originalName'])
            self.assertIn(str(row['fdcId']), row['sourceUrl'])
            if row['id'].startswith('usda-fndds-'):
                self.assertFalse(row['ingredientsKnown'])


if __name__ == '__main__':
    unittest.main()
