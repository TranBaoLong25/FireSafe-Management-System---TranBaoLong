const { crudController, crudRouter } = require('../../utils/crud');

const ctrl = crudController({
  table: 'units', idColumn: 'unit_id', orderBy: 'code',
  columns: ['code', 'name', 'parent_id', 'level', 'province_code', 'district_code', 'ward_code'],
  filterable: ['parent_id', 'level', 'province_code', 'district_code'],
});
module.exports = crudRouter(ctrl, 'unit');
