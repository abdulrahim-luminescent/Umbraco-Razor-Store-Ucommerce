UPDATE dbo.uCommerce_Payment SET FeeTotal = Fee
UPDATE dbo.uCommerce_DataType SET ValidationExpression = '^-?[0-9]+((\.|,)[0-9]{1,20})?$' WHERE TypeName = 'Number'