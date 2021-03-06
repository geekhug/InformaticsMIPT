USE [Airport]
GO

if (object_id ('[Desc1]') IS NOT NULL )
DROP VIEW [Desc1]
go
if (object_id ('[Desc2]') IS NOT NULL )
DROP VIEW [Desc2]
go
if (object_id ('[Desc3]') IS NOT NULL )
DROP VIEW [Desc3]
go
if (object_id ('[Desc4]') IS NOT NULL )
DROP VIEW [Desc4]
go

CREATE VIEW Desc1
AS

SELECT [марка-вылеты].[Название] AS [НАЗВАНИЕ МАРКИ],  [месяц], COUNT([ID вылета]) AS [КОЛ-ВО ВЫЛЕТОВ], AVG([ВРЕМЯ ПОЛЕТА, мин]) AS [СРЕДНЕЕ ВРЕМЯ ПОЛЕТА, МИН], AVG([Расстояние, км]) AS [СРЕДНЕЕ РАССТОЯНИЕ, КМ]
FROM (
	SELECT [марка-вылеты].[Название], DATENAME(month,[марка-вылеты].[Дата вылета (по расписанию)]) as [месяц], [ID вылета], DATEDIFF(MINUTE,[Время отправления],[Время прибытия]) AS [ВРЕМЯ ПОЛЕТА, мин], [Расстояние, км]
	FROM (SELECT [Название], [ID вылета], [Вылеты].[ID рейса], [Вылеты].[ID расписания по дням недели], [Дата вылета (по расписанию)], [Время отправления], [Время прибытия], [Расстояние, км]
			FROM [Марки самолетов], [Самолет], [Вылеты], [Расписание по дням недели], [Рейсы], [Маршрут]
			WHERE [Марки самолетов].[ID марки]=[Самолет].[Марка ID]
			AND [Самолет].[ID самолета]=[Вылеты].[ID самолета]
			AND [Вылеты].[ID расписания по дням недели]=[Расписание по дням недели].[ID расписания по дням недели]
			AND [Вылеты].[ID рейса]=[Рейсы].[ID рейса]
			AND [Рейсы].[ID маршрута]=[Маршрут].[ID маршрута]
			) [марка-вылеты]
		/*WHERE */
	)[марка-вылеты] 
GROUP BY [марка-вылеты].[Название],[марка-вылеты].[МЕСЯЦ];
GO

SELECT * FROM Desc1
GO

CREATE VIEW Desc2
AS
(SELECT [ID t1], [ID t2], (CAST([рейс1] AS nvarchar)+' затем '+ CAST([рейс2] AS NVARCHAR)) AS [ID рейсов], (AVG(DATEDIFF(MINUTE,[рпдн1].[Время отправления], [рпдн1].[Время прибытия])) + AVG(DATEDIFF(MINUTE,[рпдн2].[Время отправления], [рпдн2].[Время прибытия]))) as [ВРЕМЯ ПУТИ, мин]
/*С РОВНО ОДНОЙ ПЕРЕСАДКОЙ*/
FROM
(SELECT [ID t1], [ID t3], [ID t2], [рейс1], [Рейсы].[ID рейса] as [рейс2]
FROM 
	(SELECT [ID t1], [ID t3], [ID t2], [ID рейса] AS [рейс1]
	FROM
		(SELECT t13.[ID t1], t13.[ID t3], t2.[ID терминала] as [ID t2]
		FROM (
			SELECT t1.[ID терминала] as [ID t1], t3.[ID терминала] as [ID t3]
			FROM [Терминалы] as t1 JOIN [Терминалы] as t3
			on (t1.[ID терминала] is not null)
			)
		AS t13 JOIN [Терминалы] as t2
		on (t13.[ID t1] is not null)
		) t123,
		[Маршрут], [Рейсы]
	WHERE [Рейсы].[ID маршрута]=[Маршрут].[ID маршрута]
	AND [Маршрут].[Пункт вылета (код терминала)]=[t123].[ID t1]
	AND [Маршрут].[Пункт назначения (код терминала)]=[t123].[ID t3]
	AND [t123].[ID t1]!=[t123].[ID t2]
	) [с рейсом1] ,
	[Маршрут], [Рейсы] 
WHERE [Рейсы].[ID маршрута]=[Маршрут].[ID маршрута]
AND [Маршрут].[Пункт вылета (код терминала)]=[с рейсом1].[ID t3]
AND [Маршрут].[Пункт назначения (код терминала)]=[с рейсом1].[ID t2]
) [с рейсом12], 
[Расписание по дням недели] as [рпдн1], [Расписание по дням недели] as [рпдн2], [Расписание рейсов] AS [рр1], [Расписание рейсов] AS [рр2]
WHERE [с рейсом12].[рейс1]=[рр1].[ID рейса]
AND [с рейсом12].[рейс2]=[рр2].[ID рейса]
AND [рр1].[ID расписания конкретного рейса]=[рпдн1].[ID расписания]
AND [рр2].[ID расписания конкретного рейса]=[рпдн2].[ID расписания]
AND [рр1].[дата начала действия расписания]< GETDATE()
AND [рр1].[дата окончания действия расписания]> GETDATE()
AND [рр2].[дата начала действия расписания]< GETDATE()
AND [рр2].[дата окончания действия расписания]> GETDATE()
GROUP BY [ID t2], [ID t3], [ID t1], [с рейсом12].[рейс1], [с рейсом12].[рейс2]

UNION
/*БЕЗ ПЕРЕСАДОК*/
SELECT [ID t1], [ID t2], cast([С РЕЙСОМ].[рейс1] as nvarchar) as [ID рейсов], AVG(DATEDIFF(MINUTE,[Время отправления],[Время прибытия])) AS [ВРЕМЯ ПУТИ, мин]
FROM 
		(SELECT [ID t1], [ID t2], [ID рейса] AS [рейс1]
		FROM
		(	SELECT t1.[ID терминала] as [ID t1], t2.[ID терминала] as [ID t2]
			FROM [Терминалы] as t1 JOIN [Терминалы] as t2
			on (t1.[ID терминала] is not null)
			) t12, 
			[Маршрут], [Рейсы]
		WHERE [Рейсы].[ID маршрута]=[Маршрут].[ID маршрута]
		AND [Маршрут].[Пункт вылета (код терминала)]=[t12].[ID t1]
		AND [Маршрут].[Пункт назначения (код терминала)]=[t12].[ID t2]
		) [С РЕЙСОМ], 
		[Расписание рейсов], [Расписание по дням недели]
WHERE [С РЕЙСОМ].[рейс1]=[Расписание рейсов].[ID рейса]
AND [Расписание рейсов].[ID расписания конкретного рейса]=[Расписание по дням недели].[ID расписания]
AND [Расписание рейсов].[дата начала действия расписания]< GETDATE()
AND [Расписание рейсов].[дата окончания действия расписания]> GETDATE()
GROUP BY [ID t2], [ID t1], [С РЕЙСОМ].[рейс1]
)
GO

SELECT * FROM Desc2
GO

CREATE VIEW FlightsTimetable
AS 
SELECT [Вылеты].[ID вылета], [Вылеты].[ID самолета], [Вылеты].[Дата и время (фактические) вылета], [Вылеты].[Дата и время (фактические) прибытия], 
		[Вылеты].[Кол-во проданных билетов], [Рейсы].[Номер рейса], [Рейсы].[ID маршрута], [Вылеты].[Дата вылета (по расписанию)], 
		[Расписание по дням недели].[Время отправления], [Расписание по дням недели].[Время прибытия]
FROM [Вылеты], [Расписание рейсов], [Рейсы], [Расписание по дням недели]
WHERE [Рейсы].[ID рейса]=[Вылеты].[ID рейса]
AND [Расписание по дням недели].[ID расписания по дням недели]=[Вылеты].[ID расписания по дням недели]
AND [Расписание рейсов].[ID расписания конкретного рейса]=[Расписание по дням недели].[ID расписания]
AND [Рейсы].[ID рейса]=[Расписание рейсов].[ID рейса]
GO

SELECT * FROM FlightsTimetable
GO

CREATE VIEW Desc3
AS 
(SELECT [Самолет].[Регистрационный номер], [Марки самолетов].[Название], [FlightsTimetable].[Номер рейса], [FlightsTimetable].[Дата вылета (по расписанию)], 
	[FlightsTimetable].[Время отправления], [FlightsTimetable].[Время прибытия], 
	[Марки самолетов].[Число мест]-[FlightsTimetable].[Кол-во проданных билетов] AS [кол-во свободных мест]
FROM [FlightsTimetable], [Самолет], [Марки самолетов]
WHERE [Марки самолетов].[ID марки]=[Самолет].[Марка ID]
AND [Самолет].[ID самолета]=[FlightsTimetable].[ID самолета]
AND DATEPART(month, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(MONTH, GETDATE())
AND DATEPART(YEAR, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(YEAR, GETDATE())
AND [FlightsTimetable].[Кол-во проданных билетов] IS NOT NULL
UNION
SELECT [Самолет].[Регистрационный номер], [Марки самолетов].[Название], [FlightsTimetable].[Номер рейса], [FlightsTimetable].[Дата вылета (по расписанию)], 
	[FlightsTimetable].[Время отправления], [FlightsTimetable].[Время прибытия], 
	[Марки самолетов].[Число мест] AS [кол-во свободных мест]
FROM [FlightsTimetable], [Самолет], [Марки самолетов]
WHERE [Марки самолетов].[ID марки]=[Самолет].[Марка ID]
AND [Самолет].[ID самолета]=[FlightsTimetable].[ID самолета]
AND DATEPART(month, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(MONTH, GETDATE())
AND DATEPART(YEAR, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(YEAR, GETDATE())
AND [FlightsTimetable].[Кол-во проданных билетов] IS NULL
)
GO

SELECT * FROM Desc3
GO

CREATE VIEW Desc4
AS
SELECT [FlightsTimetable].[Номер рейса], A1.[Название аэропорта] AS [аэропорт вылета], A2.[Название аэропорта] AS [аэропорт прибытия], 
	[Марки самолетов].[Название] AS [марка], [FlightsTimetable].[Дата вылета (по расписанию)], [FlightsTimetable].[Время отправления], 
	[FlightsTimetable].[Время прибытия]
FROM [FlightsTimetable], [Маршрут], [Терминалы] AS T1, [Терминалы] AS T2, [Аэропорты] AS A1, [Аэропорты] AS A2,[Самолет], [Марки самолетов]
WHERE A1.[ID аэропорта]=T1.[ID аэропорта]
AND T1.[ID терминала]=[Маршрут].[Пункт вылета (код терминала)]

AND [Маршрут].[ID маршрута]=[FlightsTimetable].[ID маршрута]

AND A2.[ID аэропорта]=T2.[ID аэропорта]
AND T2.[ID терминала]=[Маршрут].[Пункт назначения (код терминала)]

AND [Марки самолетов].[ID марки]=[Самолет].[Марка ID]
AND [Самолет].[ID самолета]=[FlightsTimetable].[ID самолета]
AND DATEPART(month, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(MONTH, GETDATE())
AND DATEPART(YEAR, [FlightsTimetable].[Дата вылета (по расписанию)])=DATEPART(YEAR, GETDATE())

GO

SELECT * FROM Desc4
GO 
