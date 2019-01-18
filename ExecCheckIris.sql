
use irisdb
go

drop table if exists iris_result;
go

create table iris_result (
  id int not null identity primary key
  , "Iris_setosa" decimal(5,2) not null
  , "Iris_versicolor" DECIMAL(5,2) not null
  , "Iris_virginica" DECIMAL(5,2) not null
);
go

	insert into iris_result exec dbo.uspCheckIris N'C:\model.pkl'
--  insert into iris_result exec dbo.uspCheckIris N'C:\404.pkl'
go

select * from iris_result
