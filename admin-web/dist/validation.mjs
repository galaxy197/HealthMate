export function text(value, label, max, optional = false) {
  const result = String(value ?? '').trim();
  if ((!optional && !result) || result.length > max) throw Error(`${label}: nhập ${optional ? 'tối đa' : 'từ 1 đến'} ${max} ký tự.`);
  return result;
}
export function number(value, label, max, { optional = false, positive = false } = {}) {
  if (String(value ?? '').trim() === '' && optional) return null;
  if (String(value ?? '').trim() === '') throw Error(`${label}: cần nhập số.`);
  const result = Number(String(value).replace(',', '.'));
  if (!Number.isFinite(result) || result < 0 || (positive && result === 0) || result > max) throw Error(`${label}: nhập ${positive ? 'trên' : 'từ'} 0 đến ${max}.`);
  return result;
}
export function foodPayload(fields) {
  const alternateNames = String(fields.alternateNames ?? '').split('\n').map(s => s.trim()).filter(Boolean);
  if (alternateNames.length > 8 || alternateNames.some(s => s.length > 100)) throw Error('Tên tương đương: tối đa 8 dòng, mỗi dòng 100 ký tự.');
  const sourceUrl = text(fields.sourceUrl, 'URL nguồn', 500);
  const url = new URL(sourceUrl);
  if (url.protocol !== 'https:' || url.username || url.password) throw Error('Nguồn cần URL HTTPS hợp lệ.');
  const data = {
    name: text(fields.name, 'Tên món', 100), alternateNames,
    category: text(fields.category, 'Nhóm món', 100), servingBasis: 'per_100g', unit: 'g',
    kcalPer100g: number(fields.kcalPer100g, 'kcal/100 g', 1000),
    proteinGPer100g: number(fields.proteinGPer100g, 'Đạm', 100),
    carbsGPer100g: number(fields.carbsGPer100g, 'Carbohydrate', 100),
    fatGPer100g: number(fields.fatGPer100g, 'Chất béo', 100),
    fiberGPer100g: number(fields.fiberGPer100g, 'Chất xơ', 100, { optional: true }),
    sourceLabel: text(fields.sourceLabel, 'Tên nguồn', 160), sourceUrl,
    isEstimated: fields.isEstimated === true, isActive: fields.isActive === true,
    servingLabel: text(fields.servingLabel, 'Tên khẩu phần', 60, true) || null,
    servingGrams: number(fields.servingGrams, 'Gram/khẩu phần', 2000, { optional: true, positive: true })
  };
  if (data.proteinGPer100g + data.carbsGPer100g + data.fatGPer100g > 101) throw Error('Tổng đạm, carb và chất béo vượt khối lượng 100 g.');
  if ((data.servingLabel === null) !== (data.servingGrams === null)) throw Error('Tên khẩu phần và gram phải được nhập cùng nhau.');
  return data;
}
export function configPayload(fields) {
  const message = text(fields.maintenanceMessage, 'Thông báo bảo trì', 300, !fields.maintenanceMode);
  return { chatbotEnabled: fields.chatbotEnabled === true, foodScannerEnabled: fields.foodScannerEnabled === true, maintenanceMode: fields.maintenanceMode === true, maintenanceMessage: message };
}
export function validFoodId(value) {
  if (!/^[a-z0-9-]{1,100}$/.test(value)) throw Error('Mã món chỉ gồm chữ thường, số và dấu gạch ngang, tối đa 100 ký tự.');
  return value;
}
export function changedFields(before, after, kind) {
  if (!before || kind !== 'food_catalog') return Object.keys(after);
  return Object.keys(after).filter(key => JSON.stringify(before[key]) !== JSON.stringify(after[key]));
}
export function entityVersion(data) {
  if (!data) return null;
  const stamp = data.updatedAt;
  return typeof stamp?.seconds === 'number' && typeof stamp?.nanoseconds === 'number'
    ? `${stamp.seconds}:${stamp.nanoseconds}` : 'legacy';
}
