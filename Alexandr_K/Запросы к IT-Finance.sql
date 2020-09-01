 -- список заявок с начальной максимальной стоимостью более 15 млн
 SELECT
 br.ogrn,
 br.inn,
 br.status_id,
 br.bidderName,
 br.summBg,
 br.contract_sum
FROM ebbg.bidders_requests br 
WHERE contract_sum > 15000000;
 
 -- список заявок с ИНН агента, созданного вами в рамках 1-ой недели
SELECT
 br.ogrn,
 br.inn,
 br.summBg,
 br.status_id,
 br.bidderName
FROM ebbg.bidders_requests br 
WHERE br.inn IN (3328498350, 3327852986);

 -- список заявок в статусах "выдано", "ожидание отправки оригинала"
SELECT
 br.ogrn,
 br.inn,
 br.summBg,
 br.status_id,
 br.bidderName
FROM ebbg.bidders_requests br 
WHERE status_id IN ( 
		(SELECT id
		FROM ebbg.ebb_lovs
		WHERE pid = 17 AND lovName_id = 10),  
		(SELECT id
		FROM ebbg.ebb_lovs
		WHERE pid = 20 AND lovName_id = 10));

-- заявки, в формах финансовой отчетности которых показатель 1310 более 10 тыс
SELECT
 br.ogrn,
 br.inn,
 br.summBg,
 br.status_id,
 br.bidderName,
 bsv.amount
FROM ebbg.bidders_requests br 
INNER JOIN ebbg.bidders_statements bs1 ON br.id = bs1.request_id
INNER JOIN ebbg.bidders_statementsvalues bsv ON bs1.id = bsv.statement_id
WHERE statement_id = 22 AND bsv.amount > 10000;

-- список тендеров с начальной максимальной стоимостью более 15 млн
SELECT
 number,
 customerName,
 price,
 winnerName
FROM ebbg.ebb_tenders et
WHERE price > 15000000;

-- список тендеров по 44ФЗ, добавленных за период с декабря 2019 по текущий день
SELECT
 number,
 price,
 winnerName,
 notification_publication_datetime
FROM 
 ebbg.ebb_tenders et 
 INNER JOIN ebbg.ebb_lovs el ON el.id = et.lov_id
WHERE
 pid = 5 AND lovName_id = 15 AND
 et.notification_publication_datetime BETWEEN STR_TO_DATE('12.01.2019', '%m.%d.%Y') AND CURRENT_DATE()
;


-- список совместных процедур, где каждая процедура повторяется только один раз, а список ИНН заказчиков сохранить один в одном столбце через точку с запятой. Также  вывести их размеры обеспечения контрактов
SELECT
 et.number,
 GROUP_CONCAT(et.customerInn SEPARATOR ';'), 
 et.enforceSize
FROM -- как ты ВАЩЕ мог про него забыть!!!? 
 ebb_tenders et
GROUP BY et.number
HAVING COUNT(et.number) > 1
;

-- список процедур, которые по одному или нескольким ОКВЭД связаны с капитальным строительством
SELECT
 eo1.kod,
 et.number,
 eo1.naim
FROM 
 ebbg.ebb_tenders et
 INNER JOIN ebb_tenders_okved eto ON eto.tenders_id = et.id
 INNER JOIN ebb_okved eo1 ON eto.okved_id = eo1.id
 WHERE
eo1.kod LIKE '42%'
 -- eo1.naim LIKE 'СТРОИТЕЛЬСТВО%'
;



-- Вывести данные тех, кто фигурирует в заявке как автор, ответственный, агент(если есть) и клиент. А также пользователь, от имени которого создана заявка. 
-- Вывод должен включать: ФИО пользователя, связанного с компанией, от имени которой создана заявка; базовая роль пользователя; наименование компании пользователя; 
-- логин пользователя; email пользователя для входа в систему; ФИО агента, e-Mail агента, телефон агента, если есть. 
-- Использовать таблицы:  ebb_extendedusers, auth_user, bidders_bidders, bidders_requests.

SELECT 
 bb.fioContPers, -- ФИО пользователя, связанного с компанией, от имени которой создана заявка
 ee.category,
 -- er.name, -- базовая роль пользователя
 bb.bidderName, -- наименование компании пользователя
 au.username, -- логин пользователя
 au.email, -- email пользователя для входа в систему
 ee.fio, -- ФИО агента, 
 br.bidderEmail, -- e-Mail агента,
 ee.phone -- телефон агента, если есть 

FROM 
 bidders_requests br
 INNER JOIN bidders_bidders bb ON bb.id = br.bidder_id
 INNER JOIN ebb_extendedusers ee ON bb.author_id = ee.id
 INNER JOIN auth_user au ON ee.user_id = au.id
 -- INNER JOIN ebb_lovs el ON bb.lovprop_id = el.id
 -- INNER JOIN ebb_roles er ON el.id = er.lov_id
 GROUP BY bb.bidderName
 ;

-- Вывести информацию о пользователе и его ассоциации с компаниями, ролями и дополнительными разрешениями 
-- (вывести на тестовой voz.srvtests.com сведения для пользователей с eMail: sidorov_pd@shb.local, semin@example.ru, vanin@example.ru). 
-- Вывод должен включать: имя пользователя; ФИО пользователя; категорию пользователя; роль; наименование компании, с которой пользователь связан через роль; дополнительные разрешения; значение доп. разрешения. 
-- Использовать таблицы:  auth_user, ebb_extendedusers, ebb_extendedusersassignedinnkpp, ebb_userroles, ebb_roles, bidders_bidders, eav_value, eav_attribute.


SELECT 
 au.username,
 ee.fio,
 ee.category,
 er.name,
 bb.bidderName,
 ev.id,
 ea.name

FROM
 bidders_bidders bb
 INNER JOIN ebb_extendedusers ee ON bb.author_id = ee.id
 INNER JOIN auth_user au ON ee.user_id = au.id
 INNER JOIN ebb_userroles eu ON ee.user_id = eu.user_id
 INNER JOIN ebb_roles er ON er.id = eu.role_id
 
WHERE 
 au.email IN ('sidorov_pd@shb.local', 'semin@example.ru', 'vanin@example.ru')
;
 

-- вывести настройки типов продуктов, причем группы перечней значений настроек вывести через точку с запятой (использовать GROUP_CONCAT). 
-- Использовать таблицы: banks_productsettingslovs, banks_productsettings, ebb_lovs. 
-- При выводе получить следующие столбцы: 
-- "Активность типа продукта", 
-- "Тип продукта", 
-- "Доступные статусы для повторной подачи для одного принципала",
-- "Финальные статусы заявок", 
-- "Документы профсуждения и КР",
-- "Наименования гарантийных продуктов",
-- "Доступные статусы для повторной подачи",
-- "Документы стоп-факторов",
-- "Генерируемые документы при подаче заявки",
-- "Формы предоставления",
-- "Документы в составе предложения",
-- "Целевое использование",
-- "Величины расчетного резерва".

SELECT 
 bp.id,
 bp.is_active, -- "Активность типа продукта" 
 el.value, -- значение
 GROUP_CONCAT(DISTINCT el1.value SEPARATOR '; ') AS 'Доступные статусы для повторной подачи для одного принципала',
 GROUP_CONCAT(DISTINCT el2.value SEPARATOR '; ') AS 'Финальные статусы заявок',
 GROUP_CONCAT(DISTINCT el3.value SEPARATOR '; ') AS 'Документы профсуждения и КР',
 GROUP_CONCAT(DISTINCT el4.value SEPARATOR '; ') AS 'Наименования гарантийных продуктов',
 GROUP_CONCAT(DISTINCT el5.value SEPARATOR '; ') AS 'Доступные статусы для повторной подачи',
 GROUP_CONCAT(DISTINCT el6.value SEPARATOR '; ') AS 'Документы стоп-факторов',
 GROUP_CONCAT(DISTINCT el7.value SEPARATOR '; ') AS 'Документы в составе предложения',
 GROUP_CONCAT(DISTINCT el8.value SEPARATOR '; ') AS 'Целевое использование',
 GROUP_CONCAT(DISTINCT el9.value SEPARATOR '; ') AS 'Величины расчетного резерва',
 GROUP_CONCAT(DISTINCT el10.value SEPARATOR '; ') AS 'Генерируемые документы при подаче заявки',
 GROUP_CONCAT(DISTINCT el11.value SEPARATOR '; ') AS 'Формы предоставления'
FROM 
 banks_productsettings bp
 LEFT JOIN banks_productsettingslovs bpl ON bp.id = bpl.setting_id  
 LEFT JOIN ebb_lovs el ON el.id = bp.product_id 
 LEFT JOIN banks_productsettingslovs bpl1 ON bp.id = bpl1.setting_id 
 LEFT JOIN ebb_lovs el1 ON el1.id = bpl1.bidder_repeat_status_id -- "Доступные статусы для повторной подачи для одного принципала"
 LEFT JOIN ebb_lovs el2 ON el2.id = bpl1.final_statuses_id -- "Финальные статусы заявок"
 LEFT JOIN ebb_lovs el3 ON el3.id = bpl1.judgement_docs_id -- "Документы профсуждения и КР"
 LEFT JOIN ebb_lovs el4 ON el4.id = bpl1.product_name_id -- "Наименования гарантийных продуктов"
 LEFT JOIN ebb_lovs el5 ON el5.id = bpl1.repeat_status_id -- "Доступные статусы для повторной подачи"
 LEFT JOIN ebb_lovs el6 ON el6.id = bpl1.stopfactor_docs_id -- "Документы стоп-факторов"
 LEFT JOIN ebb_lovs el7 ON el7.id = bpl1.offer_docs_id -- "Документы в составе предложения"
 LEFT JOIN ebb_lovs el8 ON el8.id = bpl1.purpose_id -- "Целевое использование"
 LEFT JOIN ebb_lovs el9 ON el9.id = bpl1.reserve_id -- "Величины расчетного резерва"
 LEFT JOIN ebb_lovs el10 ON el10.id = bpl1.bidder_docs_id -- "Генерируемые документы при подаче заявки"
 LEFT JOIN ebb_lovs el11 ON el11.id = bpl1.issue_form_id -- "Формы предоставления"
GROUP BY bp.is_active, el.value, bp.id 
;


-- вывести список ограничений, имеющихся в инстанции, причем группы перечней значений ограничений вывести через точку с запятой (использовать GROUP_CONCAT).  
-- Использовать таблицы: ebb_restrictions, ebb_lovs, ebb_restrictions_fz, ebb_restrictions_lov_prop, ebb_restrictions_ranges, ebb_restrictions_tax_sys, methods_ranges, methods_methods.
-- При выводе получить следующие столбцы: 
-- "Наименование ограничения", 
-- "Мин. сумма", "Макс. сумма", 
-- "Список разрешенных ФЗ", 
-- "список ОКОПФ", 
-- "Название методик(и)", 
-- "Список форм налогообложения". 

SELECT
 -- el.value,
 er.name AS 'Наименование ограничения',
 GROUP_CONCAT(DISTINCT er.min_bg_sum SEPARATOR '; ') AS 'Мин. сумма',
 GROUP_CONCAT(DISTINCT er.max_bg_sum SEPARATOR '; ') AS 'Макс. сумма', 
 GROUP_CONCAT(DISTINCT el1.value SEPARATOR '; ') AS 'Список разрешенных ФЗ',
 GROUP_CONCAT(DISTINCT el2.value SEPARATOR '; ') AS 'список ОКОПФ',
 GROUP_CONCAT(DISTINCT mm.title SEPARATOR '; ') AS 'Название методик(и)',
 GROUP_CONCAT(DISTINCT el3.value SEPARATOR '; ') AS 'Список форм налогообложения'
FROM
 ebb_restrictions er
 LEFT JOIN ebb_restrictions_fz erfz ON er.id = erfz.restrictions_id
 LEFT JOIN ebb_lovs el1 ON el1.id = erfz.lovs_id
 LEFT JOIN ebb_restrictions_lov_prop erlp ON erlp.restrictions_id = er.id
 LEFT JOIN ebb_lovs el2 ON el2.id = erlp.lovs_id
 LEFT JOIN methods_methods mm ON er.method_id = mm.id
 LEFT JOIN ebb_restrictions_tax_sys erts ON erts.restrictions_id = er.id
 LEFT JOIN ebb_lovs el3 ON el3.id = erts.lovs_id
GROUP BY er.id
;


-- Вывести список конкретных продуктов, настроенных на инстанции ITF с указанием настроенных ограничений по применимости продуктов: ограничения по ФЗ, ОПФ и пр. 
-- (по полям, которые являются FK по отношению к ebb_lovs). 
-- В качестве полей для вывода указать: 
-- код продукта, 
-- наим. продукта, 
-- перечень ФЗ через точку с запятой, 
-- перечень ОПФ через точку с запятой, 
-- и т.д. по всем полям , которые являются FK по отношению к ebb_lovs. 
-- Использовать таблицы ebbg.banks_mainproductsettings, ebb_lovs.

SELECT 
 bm.name, -- наим. продукта 
 GROUP_CONCAT(DISTINCT el.value SEPARATOR '; ') AS 'перечень ОПФ',
 GROUP_CONCAT(DISTINCT el2.value SEPARATOR '; ') AS 'перечень ФЗ',
 GROUP_CONCAT(DISTINCT el1.value SEPARATOR '; ') AS 'типы продуктов',
 GROUP_CONCAT(DISTINCT el3.value SEPARATOR '; ') AS 'статусы',
 GROUP_CONCAT(DISTINCT el4.value SEPARATOR '; ') AS 'др статусы',
 GROUP_CONCAT(DISTINCT el5.value SEPARATOR '; ') AS 'ограничения',

 GROUP_CONCAT(DISTINCT el6.value SEPARATOR '; ') AS 'по каким законам можно сделать заявку',
 GROUP_CONCAT(DISTINCT el7.value SEPARATOR '; ') AS 'фин период',
 GROUP_CONCAT(DISTINCT el8.value SEPARATOR '; ') AS 'Статус проверки соответствий в блоках заявки для ролей пользователей'

FROM
 banks_mainproductsettings bm 
 LEFT JOIN banks_mainproductsettingslovs bml ON bm.id = bml.main_setting_id
 LEFT JOIN ebb_lovs el ON el.id = bml.lovprops_id
 LEFT JOIN ebb_lovs el1 ON el1.id = bml.product_types_id
 LEFT JOIN ebb_lovs el2 ON el2.id = bml.find_protocol_law_lov_id
 LEFT JOIN ebb_lovs el3 ON el3.id = bml.find_protocol_statuses_id
 LEFT JOIN ebb_lovs el4 ON el4.id = bml.take_egr_statuses_id
 LEFT JOIN ebb_lovs el5 ON el5.id = bml.refuse_reason_categories_id

 LEFT JOIN ebb_lovs el6 ON el6.id = bml.allow_request_lawlov_id 
 LEFT JOIN ebb_lovs el7 ON el7.id = bml.check_fin_forms_periods_id 
 LEFT JOIN ebb_lovs el8 ON el8.id = bml.copy_trusted_request_info_statuses_id 

GROUP BY bm.id
;

SELECT 
el.value
FROM
banks_mainproductsettingslovs bml
LEFT JOIN ebb_lovs el ON el.id = bml.copy_trusted_request_info_statuses_id;

SELECT DISTINCT
 br.status_id,
 el.value,
 el.pid,
 el.lovName_id
FROM 
 bidders_requests br
 LEFT JOIN ebb_lovs el ON el.id = br.status_id
;

-- Найти созданную вами в 1-м месяце методику
-- Вывести содержимое методики из связанных таблиц methods_methods, methods_groups, methods_questions, methods_ranges.
SELECT
  mm.id,
  mm.title AS 'Название методики',
  mm.createDateTime,
  mg.title,
  mg.calc,
  mq.title,
  mq.calc,
  mr.title,
  mr.`range`
FROM
  methods_methods mm 
  LEFT JOIN methods_groups mg  ON mm.id = mg.method_id
  LEFT JOIN methods_questions mq  ON mg.id = mq.group_id
  LEFT JOIN methods_ranges mr  ON mq.id = mr.question_id
WHERE 
  mm.title LIKE '%Карабанов%'
;

-- Выполнить запрос, чтобы найти созданные вами стоп-факторы в 1-м месяце.

SELECT
  bsg.name,
  bsg.postfix,
  bs.id,
  bs.createDateTime,
  bsq.id,
  bsq.question
FROM
  banks_stopfactors bs
  LEFT JOIN banks_stopfactorsgroups bsg ON bs.group_id = bsg.id
  LEFT JOIN banks_stopfactorsquestion bsq ON bs.question_id = bsq.id

WHERE
  bsg.name LIKE '%Карабанов%' OR
  bsg.postfix LIKE '%Карабанов%'