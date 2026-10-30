import json
import unittest
from pathlib import Path
from import_usda_bundle import ROOT, dietary_class, local_diets, local_ingredients, source_ingredients_known, portion
from usda_vietnamese import vietnamese_name


class UsdaBundleTest(unittest.TestCase):
    def test_vietnamese_names_preserve_preparation_and_original_identity(self):
        for original, words in [
            ('Bananas, raw', ['Chuối', 'sống']),
            ('Lemon juice, raw', ['Nước chanh vàng', 'sống']),
            ('Rice, white, cooked, without salt', ['Gạo', 'trắng', 'đã nấu chín', 'không thêm muối']),
            ('Chicken, breast, meat only, cooked, roasted', ['Thịt gà', 'ức', 'chỉ thịt', 'đã nấu chín', 'nướng']),
        ]:
            translated = vietnamese_name(original, 'Test', 123)
            for word in words: self.assertIn(word, translated)
            self.assertTrue(translated.endswith('123'))
            self.assertLessEqual(len(translated), 100)
        self.assertIn("McDONALD'S", vietnamese_name("McDONALD'S, hamburger", 'Đồ ăn nhanh', 456))

    def test_incomplete_product_ingredients_stay_unknown(self):
        for description, category in [('Vegetables, with sauce', '11'), ('Soup, vegetable', '11'), ('Nuts, mixed', '12')]:
            self.assertFalse(source_ingredients_known(description, category))
        self.assertTrue(source_ingredients_known('Bananas, raw', '9'))
        ingredients = local_ingredients()
        self.assertIn('Đậu phụ trắng', ingredients['vn-com-dau-rau']['ingredientNames'])
        self.assertFalse(ingredients['vn2007-7069']['ingredientsKnown'])

    def test_animal_ingredients_never_become_plant_based(self):
        for name in ["Beans, canned, with pork", "Vegetable soup, chicken broth", "Nuts, with gelatin"]:
            self.assertEqual(dietary_class(name, "16"), "nonVegetarian")
        for name in ["Beans, with butter", "Cheese, cheddar", "Spinach, breaded, fried", "Salad dressing"]:
            self.assertEqual(dietary_class(name, "11"), "unknown")
        self.assertEqual(dietary_class("Egg, whole, raw", "1"), "vegetarian")
        self.assertEqual(dietary_class("Lentils, cooked, boiled", "16"), "vegan")
        for name in ["Refried beans, canned, traditional style", "Beans, baked, home prepared", "Veggie burgers or soyburgers, unprepared", "Soymilk, chocolate", "Falafel, home-prepared"]:
            self.assertEqual(dietary_class(name, "16"), "unknown")

    def test_vietnamese_recipes_follow_reviewed_ingredients(self):
        kinds = local_diets()
        for key in ["vn2007-6001", "egg-boiled"]:
            self.assertEqual(kinds[key], "vegetarian")
        self.assertEqual(kinds["vn2007-10009"], "unknown")
        for key in ["vn-com-dau-rau", "vn-bun-dau-rau", "vn-dau-sot-ca", "vn2007-3032", "banana-raw"]:
            self.assertEqual(kinds[key], "vegan")
        for key in ["vn-pho-bo", "vn-com-tam-suon", "vn-canh-bau-tom"]:
            self.assertEqual(kinds[key], "nonVegetarian")

    def test_fractional_source_measure_is_normalized_once(self):
        row = {"id": "123", "amount": "0.5", "gram_weight": "60", "modifier": "cup, diced"}
        value = portion(row)
        self.assertEqual(value["servingGrams"], 120)
        self.assertEqual(value["portionSource"]["gramWeight"], 60)
        self.assertEqual(value["servingLabel"], "cốc USDA, diced")

    def test_invalid_and_non_edible_measures_are_not_guessed(self):
        for weight, amount, label in [("nan", "1", "cup"), ("80", "0", "slice"), ("2001", "1", "piece"), ("100", "1", "yield from bone")]:
            self.assertIsNone(portion({"id": "1", "amount": amount, "gram_weight": weight, "modifier": label}))

    def test_all_published_records_have_provenance_and_complete_macros(self):
        bundle = json.loads((ROOT / "assets/nutrition/usda-sr-legacy.json").read_text(encoding="utf-8"))
        foods = bundle["foods"]
        self.assertGreater(len(foods), 7000)
        self.assertEqual(len({f["id"] for f in foods}), len(foods))
        self.assertEqual(len({f["fdcId"] for f in foods}), len(foods))
        for food in foods:
            self.assertTrue(food['originalName'])
            self.assertEqual(food['sourceDetails']['description'], food['originalName'])
            self.assertIn(food['originalName'][:100], food['alternateNames'])
            self.assertEqual(food['ingredientNames'], [food['originalName']])
            self.assertTrue(0 < len(food["name"]) <= 100)
            self.assertEqual(food["sourceDetails"]["fdcId"], food["fdcId"])
            self.assertEqual(food["sourceDetails"]["basis"], "per_100g")
            self.assertIn(str(food["fdcId"]), food["sourceUrl"])
            self.assertTrue(all(food[k] >= 0 for k in ("kcalPer100g", "proteinGPer100g", "carbsGPer100g", "fatGPer100g")))
            if "servingGrams" in food:
                source = food["portionSource"]
                self.assertAlmostEqual(food["servingGrams"], source["gramWeight"] / source["amount"], places=5)


if __name__ == "__main__":
    unittest.main()
