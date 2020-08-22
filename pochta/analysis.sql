create database pochta encoding 'utf8' template template0;

select avg("вес (гр)"), avg(replace("стоимость (руб,коп)",',','.')::decimal) from parcel;

select round(price/weight,1), count(1)  from (
                   select round("вес (гр)", -2)                                        weight,
                          round(replace("стоимость (руб,коп)", ',', '.')::decimal) price,
                          *
                   from parcel where round("вес (гр)", -2) <>0
               ) a group by 1;

select cnt, count(1) from (
select hid, "дата оформления"::date, count(1) cnt from parcel group by 1,2) a group by 1 ;

select *
from parcel where hid='16092085-7c1f-4a9a-b6f2-75c1a522090c';

drop table if exists users ;

-- Основная таблица анализа пользователей
create table users as
select hid, count(1) отправлений
    , count(case when "с налож. платежом"='true' then 1 end) наложенных, count(case when "безбланковая отправка"='true' then 1 end) безбланковых
    , avg("вес (гр)") вес_средний, avg("стоимость (руб,коп)") цена_средняя
    , avg(case when "с налож. платежом"='true' then "вес (гр)" end) вес_налож_средний
    , avg(case when "с налож. платежом"='true' then "стоимость (руб,коп)" end) цена_налож_средняя
    , avg(case when "сумма НП (руб)">0 and "с налож. платежом"='true' then "сумма НП (руб)" end) налож_средняя
    , extract(epoch from max("дата оформления")-min("дата оформления"))::int/3600 часов
    , count(distinct "дата оформления"::date) разных_дней
    , count(distinct "индекс получателя") получателей, count(distinct "индекс отправителя"::text||"индекс получателя"::text) направлений
    , count(distinct round("вес (гр)", -2)) весов, count(distinct round("стоимость (руб,коп)"/30)*30) стоимостей_30
    , min("вес (гр)") вес_минимум, max("вес (гр)") вес_максимум, min("стоимость (руб,коп)") цена_минимум, max("стоимость (руб,коп)") цена_максмум
    , count(1)/count(distinct "дата оформления"::date) среднее_в_день
from parcel group by 1;

-- исходные данные для сегментов
select avg(вес_налож_средний), avg(цена_налож_средняя+налож_средняя), sum(отправлений), sum(наложенных) from users where  наложенных>0;

select avg(вес_налож_средний), avg(цена_налож_средняя+налож_средняя), sum(отправлений), sum(наложенных) from users where  безбланковых>0;


select avg(цена_средняя), avg(case when наложенных>0 then цена_средняя end ) from users;

select отправлений, count(1), (count(1)*отправлений/sum(отправлений) over ()*100) from users
group by 1 order by 1 desc ;

select среднее_в_день, count(1), (count(1)*среднее_в_день/sum(среднее_в_день) over ()*100) from users
group by 1 order by 1 desc ;

select весов, count(1), (count(1)*весов/sum(весов) over ()*100) from users
group by 1 order by 1 desc ;

select sum(cnt) from (
select отправлений snd, count(1) cnt from users group by 1) a where snd>=9;

select вес_максимум, count(1) from users group by 1 order by 2 desc;


-- Поиск пороговых значений сегментов
select sum(цена_средняя), sum(отправлений), sum(безбланковых),
       count(case when отправлений>1 then 1 end) cnt2, count(1)  cnt from users where разных_дней>=22;

select sum(цена_средняя), sum(отправлений), sum(безбланковых),
       count(case when отправлений>1 then 1 end) cnt2, count(1)  cnt from users where отправлений>=9;
       

-- Пример пересечения сегментов
select sum(цена_средняя), sum(отправлений), sum(безбланковых),
       count(case when отправлений>1 then 1 end) cnt2, count(1)  cnt from users where отправлений>=9 and разных_дней>=22;
       


