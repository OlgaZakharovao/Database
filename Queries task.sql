/*Функция*/
-- Создание функции Duration в таблице Order
CREATE FUNCTION [dbo].duration_change (@order_id int)  
RETURNS int
AS 
BEGIN  

    DECLARE @startdate datetime;
	    SELECT @startdate = status_date
	    FROM Status_change
	    WHERE id_order = @order_id 
	   	AND id_status = 1;
    DECLARE @enddate datetime;
	    SELECT @enddate = status_date
	    FROM Status_change
	    WHERE id_order = @order_id 
	   	AND id_status = 5; 
	DECLARE @difference int;
	IF @enddate IS NOT NULL AND @startdate IS NOT NULL
		BEGIN
			SET @difference = DATEDIFF(day, @startdate, @enddate);
		END;
	ELSE
		IF @startdate IS NOT NULL
			BEGIN
				SET @difference = DATEDIFF(day, @startdate, GETDATE()); 
			END;
		ELSE
			BEGIN
				SET @difference = 0
			END
			
	RETURN @difference;
END;

SELECT [dbo].duration_change(3) AS Area;

/*триггер*/
-- Триггер для актуализации продолжительности обработки заказов при изменении статусов заказа
CREATE trigger set_duration
on status_change
after insert
AS
BEGIN
        DECLARE @id_order int = (SELECT id_order
                                 FROM Inserted)
        DECLARE @start_date datetime = (SELECT sc.status_date
                                        FROM Status_change sc
                                        WHERE sc.id_order = @id_order AND sc.id_status = 1)
        DECLARE @end_date datetime = (SELECT status_date
                                      FROM Inserted)
        DECLARE @duration int = DATEDIFF(day, @start_date, @end_date)
      
        UPDATE [Order]
        SET duration = @duration
        WHERE id_order = @id_order;
END;

/*Проверка работы триггера*/
begin tran;
INSERT INTO Status_change 
VALUES(GETDATE(), 4, 14)
commit tran;


SELECT *
FROM ProductsCostingMoreThan(100)

















ALTER TABLE [Order]
ADD duration int AS dbo.duration_change(id_order);




-- Запрос с SELECT INTO 
-- Вытащить все заказы от одного пользователя
SELECT o.id_order, o.description, o.id_courier, o.id_store, o.id_address, o.id_collector
INTO User1_Orders
FROM [Order] o 
LEFT JOIN [User] u ON o.id_user = u.id_user
WHERE o.id_user = 1;

-- Вытащить все заказы за сегодняшний день
DECLARE @tablename NVARCHAR(50)
SET @tablename = 'Orders' + CONVERT(NVARCHAR(10), GETDATE(), 23)







/*

/*Создание триггера на установление продолжительности заказа*/
CREATE trigger set_duration
on status_change
after insert
AS
BEGIN
	
	DECLARE @id_order int = (SELECT id_order
							 FROM Inserted);
	
	DECLARE @start_date datetime = (SELECT sc.status_date
									FROM Status_change sc
									WHERE sc.id_order = @id_order
									AND sc.id_status = 1)
	DECLARE @end_date datetime = (SELECT status_date
						 		  FROM Inserted)
	DECLARE @duration int = DATEDIFF(day, @start_date, @end_date)*/
/*	
	UPDATE [Order] 
	SET duration = @duration
	WHERE id_order = @id_order;
	
END;*/


/*Проверка работы триггера*/
begin tran;
INSERT INTO Status_change 
VALUES('2023-09-02 20:17:01.000', 4, 14)
commit tran;



/*Триггер на Order на установление статуса заказа 1 при создании нового заказа*/
CREATE trigger set_status
on [Order]
after insert
AS
BEGIN
	DECLARE @id_order int = (SELECT id_order
							 FROM Inserted)
	INSERT INTO Status_change (status_date, id_status, id_order)
	VALUES(GETDATE(), 1, @id_order);
END;

/*Проверка работы триггера*/
begin tran;
INSERT INTO [Order] (id_order, description, id_courier, id_store, id_user, id_address, id_collector, duration)
VALUES(16, 'fragile', 6, 12960, 17, 17, 5, 0)
commit tran;






/*Запрос с SELECT INTO*/
SELECT o.* 
INTO Current_date_orders
FROM [Order] o  
LEFT JOIN Status_change sc ON o.id_order = sc.id_order
LEFT JOIN Status s ON sc.id_status = s.id_status
WHERE s.name = 'Recieved' AND CONVERT (date, sc.status_date) = CONVERT (date, GETDATE());


-- Запрос с EXISTS
-- Вытаскиваем доставленные заказы
SELECT o1.*
FROM [Order] o1 
WHERE EXISTS (SELECT o2.*
			  FROM [Order] o2 
			  LEFT JOIN Status_change sc ON o2.id_order = sc.id_order
			  LEFT JOIN Status s ON sc.id_status = s.id_status
			  WHERE s.name = 'Sent'
			  AND o1.id_order = o2.id_order);
			  
			  
			  
-- Первый запрос с подзапросом в FROM 
-- Количество товаров в каждом заказе

SELECT *
FROM [Order] o
JOIN 
	(SELECT id_order, SUM(quantity) AS quantity 
	 FROM Order_composition oc
	 GROUP BY id_order) AS Information
ON o.id_order = Information.id_order;

/*
SELECT DISTINCT o.*, SUM(quantity) over (partition by o.id_order) AS quantity
FROM [Order] o
INNER JOIN Order_composition oc ON o.id_order = oc.id_order;*/


			  
-- Второй запрос с подзапросом в FROM 
-- Общая стоимость заказа по каждому заказу			  
SELECT *
FROM [Order] o
JOIN 
	(SELECT oc.id_order, SUM(oc.quantity * g.price) AS total_price 
	 FROM Order_composition oc
	 LEFT JOIN Good g 
	 ON oc.id_good = g.id_good
	 GROUP BY id_order) AS Information
ON o.id_order = Information.id_order;
			  

/*Запрос, использующий манипуляции с множествами*/
-- Все продукты, которые есть в первом заказе, и которым нужен холодильник			  
(SELECT g.*
FROM Good g 
JOIN Order_composition oc 
ON g.id_good = oc.id_good
WHERE oc.id_order = 1)
INTERSECT 
(SELECT g2.*
FROM Good g2 
JOIN Category c 
ON g2.id_category = c.id_category
JOIN Good_type gt
ON c.id_good_type = gt.id_good_type
WHERE gt.storage_conditions = 'fridge');


/*Запрос, использующий оконную функцию LAG или LEAD для выполнения сравнения данных в разных периодах*/
SELECT start_info.start_date, COUNT(*) AS quantity_of_orders,
	(COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY start_info.start_date)) AS quantity_change
FROM [Order] o 
LEFT JOIN (SELECT CONVERT(date, sc.status_date) AS start_date, sc.id_status, sc.id_order
	  FROM Status_change sc
	  WHERE sc.id_status = 1) AS start_info
ON o.id_order = start_info.id_order
GROUP BY start_info.start_date;
			  
			  
/*Простой запрос с условием и формулами в SELECT (2 запроса)*/		
/*Первый запрос*/
-- Подсчёт количества заказанных продуктов
SELECT oc.id_good, g.name, SUM(oc.quantity)
FROM Order_composition oc 
JOIN Good g ON oc.id_good = g.id_good		  
GROUP BY oc.id_good, g.name;
			  
/*Второй запрос*/		
-- Подсчёт количества смен у каждого сборщика за последний месяц
SELECT s.id_collector, c.name, COUNT(s.id_collector) AS number_of_shifts
FROM Shift s
JOIN Collector c ON s.id_collector = c.id_collector
GROUP BY s.id_collector, c.name;	  
			  
/*Запрос с подзапросом в FROM, агрегированием, группировкой и сортировкой*/
-- Нахождение даты самого раннего заказа
SELECT *
FROM [User] u
LEFT JOIN (SELECT MIN(sc.status_date) as min_date, o.id_user
		   FROM [Order] o
		   JOIN Status_change sc ON o.id_order = sc.id_order
		   WHERE sc.id_status = 1
		   GROUP BY o.id_user) AS minimum_date
ON u.id_user = minimum_date.id_user
WHERE minimum_date.min_date IS NOT NULL
ORDER BY minimum_date.min_date;

-- Нахождение количества купленных товаров по категориям
SELECT c.name, SUM(summa_quantity.quantity) AS category_quantity
FROM Category c 
LEFT JOIN (SELECT SUM(oc.quantity) AS quantity, g.id_good, g.id_category 
		   FROM Good g
		   JOIN Order_composition oc ON g.id_good = oc.id_good
		   GROUP BY g.id_good, g.id_category) AS summa_quantity	   
ON c.id_category = summa_quantity.id_category
GROUP BY c.id_category, c.name
ORDER BY category_quantity DESC;

/*Запрос с внешним соединением и проверкой на наличие NULL */
-- Нахождение заказов, у которых нет feedback
SELECT o.*
FROM [Order] o
LEFT JOIN Feedback f ON o.id_order = f.id_order
WHERE f.id_feedback IS NULL;

/* Запрос с коррелированным подзапросом в SELECT(2 запроса) */
-- Первый запрос
-- Выводит сумму заказанных продуктов для всех пользователей
SELECT u.name, (SELECT SUM(g.price * oc.quantity) AS summa
				FROM [Order] o
				LEFT JOIN Order_composition oc ON o.id_order = oc.id_order
				LEFT JOIN Good g ON oc.id_good = g.id_good
				WHERE o.id_user =  u.id_user)
FROM [User] u;

-- Второй запрос
-- Выводит количество смен для всех сборщиков (collector)
SELECT c.name, (SELECT COUNT(s.id_collector) 
				FROM Shift s
				WHERE s.id_collector = c.id_collector) AS number_of_shifts
FROM Collector c; 

/*Запрос с коррелированным подзапросом в WHERE(2 запроса) */
-- Первый запрос
-- Выводит заказы, в отзыве к которому написали слово 'good'
SELECT o.*
FROM [Order] o 
WHERE id_order IN (SELECT f.id_order
				   FROM Feedback f
				   WHERE f.comment LIKE '%good%');
				  
-- Второй запрос
-- Количество заказов, которые были собраны в магазинах, расположенных в Москве
SELECT COUNT(o.id_order) AS 'number_of_orders_collected_in_stores_located_in_Moscow'
FROM [Order] o 
WHERE o.id_store IN (SELECT s.id_store
					 FROM Store s 
					 WHERE s.town LIKE N'%г.Москва%');
	
				  
-- Третий запрос				  
-- Количество заказов, совершённых пользователями, год рождения которых <= 1995 
SELECT COUNT(o.id_order) AS 'number_of_orders_purchased_by_adult_users'
FROM [Order] o 
WHERE o.id_user IN (SELECT u.id_user
					FROM [User] u 
					WHERE u.birth_date < '1996-01-01');				  
				  
				  

/*Запрос с агрегированием и выражением JOIN, включающим не менее 2 таблиц(3 запроса)*/
-- Первый запрос
-- Сколько упоминался магаз в заказе
SELECT o.id_store, COUNT(o.id_store) AS 'number_of_references', s.street, s.house, s.town, s.country
FROM Store s 
LEFT JOIN [Order] o ON s.id_store = o.id_store
WHERE o.id_store IS NOT NULL
GROUP BY o.id_store, s.street, s.house, s.town, s.country
ORDER BY 'number_of_references' DESC;



-- Второй запрос
-- Количество заказов у каждого пользователя
SELECT u.id_user, COUNT(o.id_order) AS 'number_of_orders'
FROM [Order] o 
RIGHT JOIN [User] u ON o.id_user = u.id_user  
GROUP BY u.id_user;


-- Третий запрос
-- Средняя стоимость товаров по каждой категории
SELECT c.name, AVG(g.price) AS 'average_cost_of_goods'
FROM Good g 
RIGHT JOIN Category c ON g.id_category = c.id_category
GROUP BY c.name
ORDER BY c.name;


/*Запрос с агрегированием и выражением JOIN, включающим не менее 3 таблиц/выражений*/
-- Первый запрос
-- Сумма продуктов по каждому типу товара
SELECT gt.storage_conditions, AVG(g.price) AS 'average_cost_of_goods'
FROM Good g 
LEFT JOIN Category c ON g.id_category = c.id_category
LEFT JOIN Good_type gt ON c.id_good_type = gt.id_good_type
GROUP BY gt.storage_conditions;


/*Запрос с HAVING и агрегированием*/
-- Нахождение количества людей, у которых указан только один адрес доставки
SELECT COUNT(*) AS 'number_of_users_who_have_one_address'
FROM (	SELECT l.id_user 
		FROM Lives l 
		GROUP BY l.id_user
		HAVING COUNT(l.id_address) < 2) AS number_of_users_who_have_one_address;


/*Запрос с CASE (IF) и агрегированием*/
-- Выводит статусы покупателей и их скидку, исходя из количества оформленных заказов
	
SELECT  user_status.*,
 CASE WHEN tcount > 1 THEN 'Loyal customer'
		 WHEN tcount = 1 THEN 'Tester'
	    ELSE 'Newcomer'
	    END AS 'user_status',
  CASE  WHEN tcount > 1 THEN '20%'
		 WHEN tcount = 1 THEN '10%'
	    ELSE '5%'
	    END AS 'discount'
FROM
(
SELECT u.id_user,      u.name,
	   COUNT(o.id_order) tcount
	  FROM [User] u
	  LEFT JOIN [Order] o ON u.id_user = o.id_user
	  GROUP BY u.id_user,u.name
)  AS user_status;							  
							
/*Создание представления*/	
-- Представление 1
-- Представление данных по полной информации о заказе
CREATE VIEW Order_price
AS
SELECT o.*, order_sum.order_price
FROM [Order] o 
JOIN (SELECT o.id_order, SUM(oc.quantity * g.price) AS order_price
	  FROM [Order] o 
	  LEFT JOIN Order_composition oc ON o.id_order = oc.id_order
	  LEFT JOIN Good g ON oc.id_good = g.id_good
	  GROUP BY o.id_order) AS order_sum
ON o.id_order = order_sum.id_order;

-- Вывод представления
SELECT *
FROM Order_price op
ORDER BY op.id_order;

-- Представление 2
-- Представление текущего статуса заказа по всем заказам
CREATE VIEW Current_status
AS
SELECT sc.id_order, MAX(sc.id_status) AS current_status
FROM Status_change sc
GROUP BY sc.id_order;


-- Вывод представления
SELECT *
FROM Current_status1 cs
ORDER BY cs.id_order;



/*ФУНКЦИИ*/
-- Функция, выводящая полную информацию о сборщике (Collector) и подсчитывающая общее количество смен для него 
CREATE FUNCTION number_of_shifts_of_the_collector(@id_collector INT)
RETURNS TABLE
AS RETURN
(
SELECT COUNT(s.id_shift) AS number_of_shifts
FROM Shift s
LEFT JOIN Collector c ON s.id_collector = c.id_collector
WHERE s.id_collector = @id_collector
);

SELECT *
FROM number_of_shifts_of_the_collector(3);



/*Добавление индексов*/
CREATE INDEX id_good ON Order_composition (id_good);
CREATE INDEX id_order ON Order_composition (id_order);


/*Создание процедур*/
-- Процедура 1
ALTER PROCEDURE Add_new_collector (@new_id int,
									@name varchar(100),
									@telephone_number varchar(20),
									@birth_date date)
AS
BEGIN
	BEGIN TRY;
	BEGIN TRAN;
	IF DATEDIFF(year, @birth_date,  GETDATE()) < 18
		BEGIN
			PRINT 'Current collector is younger 18 years. We cannot admit him for this job!';
			ROLLBACK TRAN;
		END;
	ELSE
		BEGIN
			INSERT INTO Collector (id_collector, name, telephone_number, birth_date)
			VALUES (@new_id, @name, @telephone_number, @birth_date);
			COMMIT TRAN;
			PRINT 'Collector successfully added into base';
		END;
	END TRY
    BEGIN CATCH;
   		PRINT 'It is impossible to insert the collector, as new_id already exists!';
    	ROLLBACK TRAN;
	END CATCH;		
END;


EXEC Add_new_collector @new_id = 9, @name = 'PETROVPETRPETROVICH', @telephone_number = '89873601275', @birth_date = '1995-01-14';
EXEC Add_new_collector @new_id = 7, @name = 'PETROVPETRPETROVICH', @telephone_number = '89873601275111111111111111111111111', @birth_date = '1995-01-14';

EXEC Add_new_collector @name = 'PETROVPETRPETROVICggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggH', @telephone_number = '89873601275', @birth_date = '1998-01-14';

SELECT DATEDIFF(year, '1995-01-14', GETDATE());






DROP SEQUENCE table_id_seq;





CREATE TABLE Shift
(
  date DATETIME NOT NULL,
  id_shift INT NOT NULL,
  id_store INT NOT NULL,
  id_collector INT NOT NULL,
  PRIMARY KEY (id_shift),
  FOREIGN KEY (id_store) REFERENCES Store(id_store),
  FOREIGN KEY (id_collector) REFERENCES Collector(id_collector)
);
		  
			  
--Выводит заказы, в составе которых присутствуют  яйца, мясо и рыба			  
SELECT o.id_order 
FROM [Order] o
LEFT JOIN Order_composition oc ON o.id_order = oc.id_order
LEFT JOIN Good g ON oc.id_good = g.id_good 
WHERE g.id_category IN (SELECT g.id_category
                   		FROM Good g2 
                   		LEFT JOIN Category c ON g2.id_category = c.id_category 
                   		WHERE c.name LIKE '%Eggs, Meat & Fish%')
GROUP BY o.id_order;			  
			  


/*Процедура, выполняющая обновление на основе результатов другого запроса*/
CREATE PROCEDURE New_shift @id_store int
AS
BEGIN
	BEGIN TRY
	        BEGIN TRAN
			DECLARE @new_worker int
			SELECT @new_worker = (SELECT TOP 1 c.id_collector   --COALESCE(COUNT(s.id_collector), 0),
								  FROM Shift s
								  RIGHT JOIN Collector c ON s.id_collector = c.id_collector
								  GROUP BY c.id_collector
								  ORDER BY COUNT(s.id_collector))
			DECLARE @newshift int
			SELECT @newshift = (SELECT TOP 1 s.id_shift
								FROM Shift s
								ORDER BY s.id_shift DESC) + 1
			
			INSERT INTO Shift(date, id_shift, id_store, id_collector)
			VALUES (GETDATE(), @newshift, @id_store, @new_worker);
			COMMIT TRAN
	END TRY
    BEGIN CATCH;
		PRINT'There is no store with such id!'
		ROLLBACK TRAN
	END CATCH;		
END;


EXEC new_shift @id_store = 6888;



SELECT TOP 1 c.id_collector   --COALESCE(COUNT(s.id_collector), 0),
FROM Shift s
RIGHT JOIN Collector c ON s.id_collector = c.id_collector
GROUP BY c.id_collector
ORDER BY COUNT(s.id_collector);




/*Одна из процедур должна использовать ветвление и содержать не менее 3 запросов*/
CREATE PROCEDURE Address_verification @street nvarchar(100),
									  @house nvarchar(10),
									  @apartment int,
									  @floor int,
									  @entrance int,
									  @town nvarchar(100),
									  @country nvarchar(100)									  
AS
BEGIN
	BEGIN TRY
		DECLARE @flg int
		SET @flg = 0
		BEGIN TRAN
		IF @country NOT IN (SELECT DISTINCT cast(s.country as varchar)
							FROM Store s)
			BEGIN
				PRINT('It is impossible to deliver goods to the country')
				SET @flg = 1
				ROLLBACK TRAN
			END
		ELSE IF @town NOT IN (SELECT DISTINCT cast(s.town as varchar)
						 	  FROM Store s) 
			BEGIN
				PRINT('It is impossible to deliver goods to the town')
				SET @flg = 1
				ROLLBACK TRAN
			END
		ELSE IF @street IS NULL OR @house IS NULL OR @apartment IS NULL OR @floor IS NULL OR @entrance IS NULL 
			     OR @town IS NULL OR @country IS NULL 
				BEGIN
					PRINT('You have entered incorrect information!')
					SET @flg = 1
					ROLLBACK TRAN
				END
		IF @flg = 0 
			BEGIN 
				DECLARE @new_id_address int
				SELECT @new_id_address = (SELECT TOP 1 a.id_address
										  FROM Address a
										  ORDER BY a.id_address DESC) + 1
			
				INSERT INTO Address (id_address, street, house, apartment, [floor], entrance, town, country)
				VALUES (@new_id_address, @street, @house, @apartment, @floor, @entrance, @town, @country);
				COMMIT TRAN;
				PRINT 'Address successfully added into base';
			END
			
	END TRY
	BEGIN CATCH
		PRINT('Error while execution');
		ROLLBACK TRAN;
		
	END CATCH;
END;

-- Попытка ввода адреса, в городе / стране которого нет магазина
EXEC Address_verification @street = 'AA', 
                  		  @house = 10,
						  @apartment = 10,
						  @floor = 10,
						  @entrance  = 10,
						  @town = 'a',
						  @country = 'Germany';		

						 
						 
						 
						 
						 
						 
						 
						
						 
						 
						 
						 
-- Попытка ввода адреса, в городе / стране которого есть магазин
EXEC Address_verification @street = N'st. Letnaja', 
                  		  @house = 10,
						  @apartment = 10,
						  @floor = 10,
						  @entrance  = 10,
						  @town = N'g.Mytischi',
						  @country = N'Russia';	

						 
						 
						 
						 
						 
						 
						 

						 
INSERT INTO Address (id_address, street, house, apartment, [floor], entrance, town, country)
				VALUES (70, N'ДДД', 2, 2, 2, 2, N'ДДД', N'Р РѕСЃСЃРёСЏ');						 
						 
						 
						 
						 
SELECT DISTINCT s.country
							FROM Store s
							WHERE cast(s.country as varchar) = 'Россия';
	
							









