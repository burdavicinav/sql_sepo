/* триггеры на materials */
ALTER TRIGGER tbiu_materials DISABLE;
ALTER TRIGGER tair_materials DISABLE;
ALTER TRIGGER taiud_materials DISABLE;

ALTER TRIGGER tbiu_stock_other DISABLE;
ALTER TRIGGER tair_stock_other DISABLE;
ALTER TRIGGER taiud_stock_other DISABLE;

/* триггеры на stockObj */
ALTER TRIGGER tbiu_stockobj DISABLE;
ALTER TRIGGER taiur_stockobj DISABLE;
ALTER TRIGGER taiud_stockobj DISABLE;

/* триггеры на экспорт */
ALTER TRIGGER taiur_sepo_export_materials DISABLE;
ALTER TRIGGER tai_sepo_export_materials DISABLE;
ALTER TRIGGER tau_sepo_export_materials DISABLE;