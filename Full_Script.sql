create EXTENSION chkpass;
CREATE EXTENSION plpythonu;


create Table Клиент(
  id_клиента SERIAL PRIMARY KEY ,
  Имя varchar(30) not NULL,
  Фамилия varchar(30) not NULL,
  Отчество varchar(30) not NULL,
  Номер_паспорта varchar(30) not NULL UNIQUE,
  Номер_Телефона varchar(30) not NULL UNIQUE
);
create Table Договоры(
  id_договора serial PRIMARY KEY,
  Клиент integer references Клиент(id_клиента)
  ON DELETE CASCADE ,
  Менеджер integer references Менеджеры(id_менеджера)
  On DELETE CASCADE ,
  Число_создания timestamp not null
);
create Table Менеджеры(
  id_менеджера SERIAL PRIMARY KEY ,
  Имя varchar(30) not NULL,
  Фамилия varchar(30) not NULL,
  Должность varchar(30) not NULL
);
create TABLE Счета(
  id_счёта SERIAL PRIMARY KEY,
  Договор integer references Договоры(id_договора)
  ON DELETE CASCADE
);
create table Валюты(
  id_валюты SERIAL PRIMARY KEY ,
  Наименование_валюты varchar(30) not NULL check
  (Наименование_валюты ='RUB' or Наименование_валюты = 'BYN' or
  Наименование_валюты = 'USD'),
  Сумма money NOT NULL default 0.0,
  Код_счёта integer references Счета(id_счёта)
  ON DELETE CASCADE
);
create table Пароли(
  id_пароля SERIAL PRIMARY KEY ,
  Логин varchar(16) NOT NULL UNIQUE,
  Пароль varchar(30) NOT NULL UNIQUE,
  FOREIGN KEY (id_пароля) references
  Банковские_карты(id_карты) ON DELETE CASCADE
);
create table Операции(
  id_операции SERIAL PRIMARY KEY ,
  id_cчёта integer references Счета(id_счёта)
  ON DELETE CASCADE ,
  Сумма money NOT NULL default 0,
  Тип_операции varchar(30) NOT NULL ,
  Дата_операции timestamp not null
);
create table Банковские_карты(
  id_карты SERIAL PRIMARY KEY ,
  Счёт integer references Счета(id_счёта)
  ON DELETE CASCADE ,
  Срок_действия timestamp NOT NULL,
  CVV smallint NOT NULL UNIQUE,
  Тип_карты varchar(15) not null check (Тип_карты = 'Бесконтактная' or
  Тип_карты = 'Контактная') default 'Контактная'
);

-----------------------------------------------------------------------------

create or replace function is_exsist(фамил varchar(30),ном_паспорта varchar(30),
                          ном_тел varchar(30)) returns boolean AS $$
declare r RECORD;
begin
  for r in
    select Фамилия,Номер_паспорта,Номер_Телефона from Клиент
  LOOP
    if r.Фамилия = фамил and r.Номер_Телефона = ном_тел and r.Номер_паспорта = ном_паспорта THEN
      return TRUE;
    else
      return FALSE;
    end if;
  end loop;
end;
$$ LANGUAGE plpgsql;
select * from is_exsist('m','ab','6');
drop function is_exsist;

------------------------------------------------------------------------------

create or replace function create_client(имяя varchar(30),фам varchar(30),
                      отчеств varchar(30),ном_паспорта varchar(15),
                      номер_тел smallint) returns integer as $$
declare
  tempp integer;
  tempp2 integer;
  rww RECORD;
  incrementt int = 0;
  firstt int = 0;
  begin

  for rww in select * from Менеджеры
  loop
    firstt = min(rww.id_менеджера);
    incrementt = incrementt + 1;
  end loop;

  insert into Клиент(Имя,Фамилия,Отчество,Номер_паспорта,Номер_Телефона)
  values(имяя,фам,отчеств,ном_паспорта,номер_тел)
  returning id_клиента into tempp;

  insert into Договоры(Клиент, Менеджер, Число_создания)
  values (tempp,random_between(firstt,incrementt),current_timestamp)
  returning id_договора into tempp2;
  return tempp2;
  end;
$$ language plpgsql;
select * from create_client('v','m','s','abd','6');
drop procedure create_client(имяя varchar, фам varchar, отчеств varchar, ном_паспорта varchar, номер_тел smallint);

------------------------------------------------------------------------

create or replace function create_schet(ид integer)
  returns integer
as $$
  declare
  tempp integer = 0;
begin
   insert into Счета(Договор)
   values (ид) returning id_счёта into tempp;
   insert into Валюты(Наименование_валюты, Код_счёта)
   values ('RUB',tempp),('BYN',tempp),('USD',tempp);
   return tempp;
end;
$$ language plpgsql;
select * from create_schet('2');
drop function create_schet(ид integer);

------------------------------------------------------------------------------

create or replace procedure create_manager(имяя varchar(30),фамилияя varchar(30),должност varchar(30))
  as $$
  insert into Менеджеры(Имя,Фамилия,Должность)
  values(имяя,фамилияя,должност)
$$ language sql;
call create_manager('132','efw2ef','12fe');
drop procedure create_manager(имяя varchar, фамилияя varchar, должност varchar);

------------------------------------------------------------------------------

create or replace function create_card(тип_карт varchar(15),номер_счёта integer,
                      ллогин varchar(30),ппароль varchar(15)) returns integer as $$
  begin
  insert into Банковские_карты(Счёт,Срок_действия,CVV,Тип_карты)
  values(номер_счёта,current_timestamp + (3 || 'year')::interval  ,random_between(100,999),тип_карт);

  insert into Пароли(Логин, Пароль)
  values (ллогин,ппароль);

  return номер_счёта;
  end;
$$ language plpgsql;
drop function create_card(тип_карт varchar, номер_счёта integer, ллогин varchar, ппароль varchar);
select * from create_card('Бесконтактная',1,'dde','2d');

------------------------------------------------------------------------------

create or replace function add_money(счёт integer,деньги float,валюта varchar(30))
  returns boolean as $$
begin
  update Валюты set Сумма = Сумма + деньги::numeric::money where Код_счёта = счёт
                                           and Наименование_валюты = валюта;
  if FOUND then
    insert into Операции(id_cчёта,Сумма,Тип_операции,Дата_операции) values
                        (счёт,деньги::numeric::money,'Пополнение счёта',current_timestamp);
  end if;
  return FOUND;
end;
$$ language plpgsql;
select * from add_money(1,10.0,'BYN');
drop function add_money(счёт integer, деньги float, валюта varchar);

------------------------------------------------------------------------------

create or replace function pop_money(деньги float,ном_счёт integer,валюта varchar(30))
  returns boolean as $$
declare tempp money;
begin
  select into tempp Сумма from Валюты where Код_счёта = ном_счёт
                                        and Наименование_валюты = валюта;
  if tempp - деньги::numeric::money < 0.0::numeric::money then
    return FALSE;
  else
     update Валюты set Сумма = Сумма - деньги::numeric::money where Код_счёта = ном_счёт
                                              and Наименование_валюты = валюта;
    if FOUND then
      insert into Операции(id_cчёта,Сумма,Тип_операции,Дата_операции) values
                        (ном_счёт,деньги::numeric::money,'Снятие средств',current_timestamp);
    end if;
  END IF ;
  return FOUND;
end;
$$ language plpgsql;
select * from pop_money(0.03,1,'USD');
drop function pop_money(деньги float, ном_счёт integer, валюта varchar);

----------------------------------------------------------------------------

create or replace function transact(номер_счёта_своей_карты integer,номер_карты_куда integer,
  действительность timestamp,суммаа float,валюта varchar(30))
  returns boolean as $$
  declare
    checkk RECORD;
    your money;
  begin
    select into your Сумма from Валюты where Код_счёта = номер_счёта_своей_карты
                                             and Наименование_валюты = валюта;
      if your - суммаа::numeric::money < 0::numeric::money then
        return false;
      else
        for checkk in
          select id_карты,Счёт,Срок_действия from Банковские_карты
        loop
          if checkk.id_карты = номер_карты_куда and checkk.Срок_действия = действительность and суммаа > 0 then
            Update Валюты set Сумма = Сумма + суммаа::numeric::money where Код_счёта = checkk.Счёт
                                                       and Наименование_валюты = валюта;
            UPDATE Валюты set Сумма = Сумма - суммаа::numeric::money where Код_счёта = номер_счёта_своей_карты
                                                       and Наименование_валюты = валюта;
            if FOUND then
                insert into Операции(id_cчёта,Сумма,Тип_операции,Дата_операции) values
                                 (номер_счёта_своей_карты,суммаа::numeric::money,'Перевод средств',current_timestamp);
            end if;
            return true;
          end if;
        end loop;
      end if;
    return false;
  end;
$$ language plpgsql;
select * from transact(1,2,'2021-12-04 18:27:45.456525',1.0,'USD');
drop function transact(номер_счёта_своей_карты integer, номер_карты_куда integer,
  действительность timestamp, суммаа float, валюта varchar);

------------------------------------------------------------------------------

create or replace function trade(ном_счёта integer,в_какую_валюту varchar(30),
  из_какой_валюты varchar(30),суммма float) returns boolean
AS $$
declare
  koof float = 0;
  checkk money = 0;
  checkk2 money = 0;
begin
  select into koof * from poluch_koof(в_какую_валюту,из_какой_валюты);
  select into checkk Сумма from Валюты where  Код_счёта = ном_счёта
                                          and Наименование_валюты = из_какой_валюты;
  select into checkk2 Сумма from Валюты where Код_счёта = ном_счёта
                                          and Наименование_валюты = в_какую_валюту;
  if checkk = 0.0::numeric::money then
    return false;
  end if;
  if checkk - суммма::numeric::money < 0.0::numeric::money then
    return false;
  end if;
  if в_какую_валюту = 'USD' and из_какой_валюты = 'BYN' then
    update Валюты set Сумма = Сумма + (суммма / koof)::numeric::money where Наименование_валюты = в_какую_валюту
                                          and Код_счёта = ном_счёта;
    update Валюты set Сумма = Сумма - суммма::numeric::money where Наименование_валюты = из_какой_валюты
                                          and Код_счёта = ном_счёта;
    if FOUND then
        insert into Операции(id_cчёта,Сумма,Тип_операции,Дата_операции) values
                            (ном_счёта,(суммма / koof)::numeric::money,'Обмен средств',current_timestamp);
    end if;
    return True;
  end if;
  update Валюты set Сумма = Сумма + (суммма * koof)::numeric::money where Наименование_валюты = в_какую_валюту
                                          and Код_счёта = ном_счёта;
  update Валюты set Сумма = Сумма - суммма::numeric::money where Наименование_валюты = из_какой_валюты
                                          and Код_счёта = ном_счёта;
  if FOUND then
      insert into Операции(id_cчёта,Сумма,Тип_операции,Дата_операции) values
                          (ном_счёта,(суммма / koof)::numeric::money,'Обмен средств',current_timestamp);
  end if;
  return true;
end;
$$ language plpgsql;
select * from trade(1,'BYN','USD',1.0);
drop function trade(ном_счёта integer, в_какую_валюту varchar, из_какой_валюты varchar, суммма float);


create or replace function poluch_koof(valuta_v varchar(30),valuta_iz varchar(30))
  returns float
  as $$
  import urllib
  import json

  d=False

  if valuta_iz == 'BYN':
      if valuta_v == 'BYN':
          return 0.0
      response = urllib.urlopen('http://www.nbrb.by/API/ExRates/Rates?Periodicity=0')
      data = json.loads(response.read())
      for i in data:
          for a in i:
              if i.get(a)==valuta_v and a=='Cur_Abbreviation':
                  d=True
              if d==True and a=='Cur_OfficialRate':
                  koof=i.get(a)
                  return koof


  if valuta_iz == 'RUB':
      if valuta_v == 'RUB':
          return 0.0
      response = urllib.urlopen('https://www.cbr-xml-daily.ru/daily_json.js')
      data = json.loads(response.read())
      for i in data:
          if i=='Valute':
              b = data.get(i)
      for bb in b:
          if bb == valuta_v:
              cc = b.get(bb)
      for val in cc:
          if val == 'Value':
              koof=cc.get(val)
              return koof

  if valuta_iz == 'USD':
      if valuta_v == 'USD':
          return 0.0
      if valuta_v == 'RUB':
          response = urllib.urlopen('https://www.cbr-xml-daily.ru/daily_json.js')
          data = json.loads(response.read())
          for i in data:
              if i=='Valute':
                  b = data.get(i)
          for bb in b:
              if bb == 'USD':
                  cc = b.get(bb)
          for val in cc:
              if val == 'Value':
                  koof=cc.get(val)
                  return koof
      if valuta_v == 'BYN':
          response = urllib.urlopen('http://www.nbrb.by/API/ExRates/Rates?Periodicity=0')
          data = json.loads(response.read())
          for i in data:
              for a in i:
                  if i.get(a)=='USD' and a=='Cur_Abbreviation':
                      d=True
                  if d==True and a=='Cur_OfficialRate':
                      koof=i.get(a)
                      return koof

  return 0.0
  $$ language plpythonu;
drop function poluch_koof(valuta_v varchar, valuta_iz varchar);

--------------------------------------------------------------------------------------

create or replace procedure Export_for_Tables()
as $$
begin
copy (select table_to_xml('Клиент',true , false ,'')) to 'D:\client.xml' encoding 'UTF8';
copy (select table_to_xml('Договоры',true , false ,'')) to 'D:\dogovor.xml' encoding 'UTF8';
copy (select table_to_xml('Менеджеры',true , false ,'')) to 'D:\manager.xml' encoding 'UTF8';
copy (select table_to_xml('Счета',true , false ,'')) to 'D:\schet.xml' encoding 'UTF8';
copy (select table_to_xml('Валюты',true , false ,'')) to 'D:\valuta.xml' encoding 'UTF8';
copy (select table_to_xml('Банковские_карты',true , false ,'')) to 'D:\card.xml' encoding 'UTF8';
copy (select table_to_xml('Пароли',true , false ,'')) to 'D:\passwords.xml' encoding 'UTF8';
copy (select table_to_xml('Операции',true , false ,'')) to 'D:\operations.xml' encoding 'UTF8';
end;
$$ language plpgsql;
call Export_for_Tables();
drop procedure  Export_for_Tables();



create or replace procedure Export_for_Database()
as $$
begin
copy (select database_to_xml(true,false ,'')) to 'D:\database.xml' encoding 'UTF-8';
end;
$$ language plpgsql;
call Export_for_Database();
drop procedure  Export_for_Database();

--------------------------------------------------------------------------------------

create or replace procedure Import()
as $$
begin
INSERT INTO Клиент(id_клиента,Имя,Фамилия,Отчество,Номер_паспорта,Номер_Телефона)
  SELECT (xpath('//row/id_клиента/text()', x))[1]::text::int AS id_клиента,
         (xpath('//row/Имя/text()', x))[1]::text::varchar(30) AS Имя,
         (xpath('//row/Фамилия/text()', x))[1]::text::varchar(30) AS Фамилия,
         (xpath('//row/Отчество/text()', x))[1]::text::varchar(30) AS Отчество,
         (xpath('//row/Номер_паспорта/text()', x))[1]::text::varchar(30) AS Номер_паспорта,
         (xpath('//row/Номер_Телефона/text()', x))[1]::text::varchar(30) AS Номер_Телефона
  FROM unnest(xpath('//row', pg_read_file('D:\client.xml')::xml)) x;
end;
$$ language plpgsql;
select * from Import('D:\client.  xml');
drop function Import();


-----------------------------------------------------------------------------
select * from Валюты;
insert into Валюты(Наименование_валюты, Код_счёта)  values ('BYN',1),('USD',1),('RUB',1);
drop table Валюты;
drop table Счета;
drop table Банковские_карты;
drop table Пароли;
drop table Операции;
drop table Договоры;
drop table Менеджеры;
drop table Клиент;
select * from Клиент;
select * from Менеджеры;
select * from Договоры;
select * from Валюты;
select * from Операции;
select * from Счета;
select * from Банковские_карты;
delete from Клиент values where id_клиента=14;
delete from Договоры values where id_договора='2';
delete from Клиент values where id_клиента='6';
alter table Банковские_карты alter column Тип_карты type varchar(15);
CREATE OR REPLACE FUNCTION random_between(low INT ,high INT)
   RETURNS INT
  AS $$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language plpgsql STRICT;

create or replace procedure inser() as $$
declare
  increm int=0;
begin
  loop
  insert into Менеджеры(Имя,Фамилия,Должность)
  values ('de'|| random_between(1,100000),'fef'|| random_between(1,100000),'jknj'|| random_between(1,100000));
  increm = increm + 1;
  exit when increm = 100000;
  end loop;
  end;
$$ language plpgsql;
call inser();

create user vlad password 'vlad';

create index For_Manager on Менеджеры using btree(id_менеджера);
drop index For_Manager;
create index For_Manager on Менеджеры using brin(id_менеджера);
delete from Клиент where id_клиента=16;

insert into Клиент(Имя,Фамилия,Отчество,Номер_паспорта,Номер_Телефона)
values ('Vewf','ewf','fef','fwef','fweef');

select id_карты, Наименование_валюты, Сумма
from Валюты
left join Банковские_карты on Валюты.Код_счёта = Банковские_карты.id_карты having Сумма>0::money
ORDER BY Банковские_карты.id_карты Asc ;
