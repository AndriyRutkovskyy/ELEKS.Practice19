if object_id('dbo.uspCheckIris', N'P') is not null
  drop procedure dbo.uspCheckIris
go

create procedure dbo.uspCheckIris(
    @path as nvarchar(255)
)
as
begin
  declare @result as int = 0
  declare @severity as int = 16
  declare @state as int = 1
  declare @savePointName as sysname = 'dbo.uspCheckIris'
  declare @trancount as int = @@trancount

  declare @isFileExists as int
  
  begin try
    
	exec master.dbo.xp_fileexist @path, @isFileExists OUTPUT
 
	if @isFileExists = 0
		raiserror('Stored procedure "%s": Model not found!!! File "%s" does not exist.'
		, @severity, @state
		, N'dbo.uspCheckIris'
		, @path
	)

    if @trancount = 0
      begin transaction
    else
      save transaction @savePointName

EXEC sp_execute_external_script @language = N'Python',
@script = N'
import pandas as pd
from sklearn.externals import joblib
model_path = mdl_path
with open(model_path, "rb") as pickle_file:
	loaded_model = joblib.load(pickle_file)
	result = loaded_model.predict_proba(data_frame)
	df = pd.DataFrame.from_records(result, columns=["Iris setosa","Iris versicolor","Iris virginica"])
	OutputDataSet = df
'
, @input_data_1 = N'
	select	cast(sepal_length as float) as sepal_length
		,	cast(sepal_width as float) as sepal_width
		,	cast(petal_length as float) as petal_length
		,	cast(petal_width as float) as petal_width
	from	iris_serving
	'
, @input_data_1_name = N'data_frame'
, @params = N'@mdl_path nvarchar(max)'
, @mdl_path = @path
WITH RESULT SETS (
	(Iris_setosa decimal(5,2), Iris_versicolor decimal(5,2), Iris_virginica decimal(5,2))
)
	
  lbsuccess:
    if @trancount = 0
      commit;
  end try
  begin catch
    set @result = 1
    declare @xstate as int = xact_state()

    if @xstate = -1
      rollback
    else if @xstate = 1 and @trancount = 0
      rollback
    else if @xstate = 1 and @trancount > 0
      rollback transaction @savePointName

    ;throw
  end catch

  return @result
end
go