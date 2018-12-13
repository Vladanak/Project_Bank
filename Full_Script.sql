create EXTENSION chkpass;
CREATE EXTENSION plpythonu;


create Table ������(
  id_������� SERIAL PRIMARY KEY ,
  ��� varchar(30) not NULL,
  ������� varchar(30) not NULL,
  �������� varchar(30) not NULL,
  �����_�������� varchar(30) not NULL UNIQUE,
  �����_�������� varchar(30) not NULL UNIQUE
);
create Table ��������(
  id_�������� serial PRIMARY KEY,
  ������ integer references ������(id_�������)
  ON DELETE CASCADE ,
  �������� integer references ���������(id_���������)
  On DELETE CASCADE ,
  �����_�������� timestamp not null
);
create Table ���������(
  id_��������� SERIAL PRIMARY KEY ,
  ��� varchar(30) not NULL,
  ������� varchar(30) not NULL,
  ��������� varchar(30) not NULL
);
create TABLE �����(
  id_����� SERIAL PRIMARY KEY,
  ������� integer references ��������(id_��������)
  ON DELETE CASCADE
);
create table ������(
  id_������ SERIAL PRIMARY KEY ,
  ������������_������ varchar(30) not NULL check
  (������������_������ ='RUB' or ������������_������ = 'BYN' or
  ������������_������ = 'USD'),
  ����� money NOT NULL default 0.0,
  ���_����� integer references �����(id_�����)
  ON DELETE CASCADE
);
create table ������(
  id_������ SERIAL PRIMARY KEY ,
  ����� varchar(16) NOT NULL UNIQUE,
  ������ varchar(30) NOT NULL UNIQUE,
  FOREIGN KEY (id_������) references
  ����������_�����(id_�����) ON DELETE CASCADE
);
create table ��������(
  id_�������� SERIAL PRIMARY KEY ,
  id_c���� integer references �����(id_�����)
  ON DELETE CASCADE ,
  ����� money NOT NULL default 0,
  ���_�������� varchar(30) NOT NULL ,
  ����_�������� timestamp not null
);
create table ����������_�����(
  id_����� SERIAL PRIMARY KEY ,
  ���� integer references �����(id_�����)
  ON DELETE CASCADE ,
  ����_�������� timestamp NOT NULL,
  CVV smallint NOT NULL UNIQUE,
  ���_����� varchar(15) not null check (���_����� = '�������������' or
  ���_����� = '����������') default '����������'
);

-----------------------------------------------------------------------------

create or replace function is_exsist(����� varchar(30),���_�������� varchar(30),
                          ���_��� varchar(30)) returns boolean AS $$
declare r RECORD;
begin
  for r in
    select �������,�����_��������,�����_�������� from ������
  LOOP
    if r.������� = ����� and r.�����_�������� = ���_��� and r.�����_�������� = ���_�������� THEN
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

create or replace function create_client(���� varchar(30),��� varchar(30),
                      ������� varchar(30),���_�������� varchar(15),
                      �����_��� smallint) returns integer as $$
declare
  tempp integer;
  tempp2 integer;
  rww RECORD;
  incrementt int = 0;
  firstt int = 0;
  begin

  for rww in select * from ���������
  loop
    firstt = min(rww.id_���������);
    incrementt = incrementt + 1;
  end loop;

  insert into ������(���,�������,��������,�����_��������,�����_��������)
  values(����,���,�������,���_��������,�����_���)
  returning id_������� into tempp;

  insert into ��������(������, ��������, �����_��������)
  values (tempp,random_between(firstt,incrementt),current_timestamp)
  returning id_�������� into tempp2;
  return tempp2;
  end;
$$ language plpgsql;
select * from create_client('v','m','s','abd','6');
drop procedure create_client(���� varchar, ��� varchar, ������� varchar, ���_�������� varchar, �����_��� smallint);

------------------------------------------------------------------------

create or replace function create_schet(�� integer)
  returns integer
as $$
  declare
  tempp integer = 0;
begin
   insert into �����(�������)
   values (��) returning id_����� into tempp;
   insert into ������(������������_������, ���_�����)
   values ('RUB',tempp),('BYN',tempp),('USD',tempp);
   return tempp;
end;
$$ language plpgsql;
select * from create_schet('2');
drop function create_schet(�� integer);

------------------------------------------------------------------------------

create or replace procedure create_manager(���� varchar(30),�������� varchar(30),�������� varchar(30))
  as $$
  insert into ���������(���,�������,���������)
  values(����,��������,��������)
$$ language sql;
call create_manager('132','efw2ef','12fe');
drop procedure create_manager(���� varchar, �������� varchar, �������� varchar);

------------------------------------------------------------------------------

create or replace function create_card(���_���� varchar(15),�����_����� integer,
                      ������ varchar(30),������� varchar(15)) returns integer as $$
  begin
  insert into ����������_�����(����,����_��������,CVV,���_�����)
  values(�����_�����,current_timestamp + (3 || 'year')::interval  ,random_between(100,999),���_����);

  insert into ������(�����, ������)
  values (������,�������);

  return �����_�����;
  end;
$$ language plpgsql;
drop function create_card(���_���� varchar, �����_����� integer, ������ varchar, ������� varchar);
select * from create_card('�������������',1,'dde','2d');

------------------------------------------------------------------------------

create or replace function add_money(���� integer,������ float,������ varchar(30))
  returns boolean as $$
begin
  update ������ set ����� = ����� + ������::numeric::money where ���_����� = ����
                                           and ������������_������ = ������;
  if FOUND then
    insert into ��������(id_c����,�����,���_��������,����_��������) values
                        (����,������::numeric::money,'���������� �����',current_timestamp);
  end if;
  return FOUND;
end;
$$ language plpgsql;
select * from add_money(1,10.0,'BYN');
drop function add_money(���� integer, ������ float, ������ varchar);

------------------------------------------------------------------------------

create or replace function pop_money(������ float,���_���� integer,������ varchar(30))
  returns boolean as $$
declare tempp money;
begin
  select into tempp ����� from ������ where ���_����� = ���_����
                                        and ������������_������ = ������;
  if tempp - ������::numeric::money < 0.0::numeric::money then
    return FALSE;
  else
     update ������ set ����� = ����� - ������::numeric::money where ���_����� = ���_����
                                              and ������������_������ = ������;
    if FOUND then
      insert into ��������(id_c����,�����,���_��������,����_��������) values
                        (���_����,������::numeric::money,'������ �������',current_timestamp);
    end if;
  END IF ;
  return FOUND;
end;
$$ language plpgsql;
select * from pop_money(0.03,1,'USD');
drop function pop_money(������ float, ���_���� integer, ������ varchar);

----------------------------------------------------------------------------

create or replace function transact(�����_�����_�����_����� integer,�����_�����_���� integer,
  ���������������� timestamp,������ float,������ varchar(30))
  returns boolean as $$
  declare
    checkk RECORD;
    your money;
  begin
    select into your ����� from ������ where ���_����� = �����_�����_�����_�����
                                             and ������������_������ = ������;
      if your - ������::numeric::money < 0::numeric::money then
        return false;
      else
        for checkk in
          select id_�����,����,����_�������� from ����������_�����
        loop
          if checkk.id_����� = �����_�����_���� and checkk.����_�������� = ���������������� and ������ > 0 then
            Update ������ set ����� = ����� + ������::numeric::money where ���_����� = checkk.����
                                                       and ������������_������ = ������;
            UPDATE ������ set ����� = ����� - ������::numeric::money where ���_����� = �����_�����_�����_�����
                                                       and ������������_������ = ������;
            if FOUND then
                insert into ��������(id_c����,�����,���_��������,����_��������) values
                                 (�����_�����_�����_�����,������::numeric::money,'������� �������',current_timestamp);
            end if;
            return true;
          end if;
        end loop;
      end if;
    return false;
  end;
$$ language plpgsql;
select * from transact(1,2,'2021-12-04 18:27:45.456525',1.0,'USD');
drop function transact(�����_�����_�����_����� integer, �����_�����_���� integer,
  ���������������� timestamp, ������ float, ������ varchar);

------------------------------------------------------------------------------

create or replace function trade(���_����� integer,�_�����_������ varchar(30),
  ��_�����_������ varchar(30),������ float) returns boolean
AS $$
declare
  koof float = 0;
  checkk money = 0;
  checkk2 money = 0;
begin
  select into koof * from poluch_koof(�_�����_������,��_�����_������);
  select into checkk ����� from ������ where  ���_����� = ���_�����
                                          and ������������_������ = ��_�����_������;
  select into checkk2 ����� from ������ where ���_����� = ���_�����
                                          and ������������_������ = �_�����_������;
  if checkk = 0.0::numeric::money then
    return false;
  end if;
  if checkk - ������::numeric::money < 0.0::numeric::money then
    return false;
  end if;
  if �_�����_������ = 'USD' and ��_�����_������ = 'BYN' then
    update ������ set ����� = ����� + (������ / koof)::numeric::money where ������������_������ = �_�����_������
                                          and ���_����� = ���_�����;
    update ������ set ����� = ����� - ������::numeric::money where ������������_������ = ��_�����_������
                                          and ���_����� = ���_�����;
    if FOUND then
        insert into ��������(id_c����,�����,���_��������,����_��������) values
                            (���_�����,(������ / koof)::numeric::money,'����� �������',current_timestamp);
    end if;
    return True;
  end if;
  update ������ set ����� = ����� + (������ * koof)::numeric::money where ������������_������ = �_�����_������
                                          and ���_����� = ���_�����;
  update ������ set ����� = ����� - ������::numeric::money where ������������_������ = ��_�����_������
                                          and ���_����� = ���_�����;
  if FOUND then
      insert into ��������(id_c����,�����,���_��������,����_��������) values
                          (���_�����,(������ / koof)::numeric::money,'����� �������',current_timestamp);
  end if;
  return true;
end;
$$ language plpgsql;
select * from trade(1,'BYN','USD',1.0);
drop function trade(���_����� integer, �_�����_������ varchar, ��_�����_������ varchar, ������ float);


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
copy (select table_to_xml('������',true , false ,'')) to 'D:\client.xml' encoding 'UTF8';
copy (select table_to_xml('��������',true , false ,'')) to 'D:\dogovor.xml' encoding 'UTF8';
copy (select table_to_xml('���������',true , false ,'')) to 'D:\manager.xml' encoding 'UTF8';
copy (select table_to_xml('�����',true , false ,'')) to 'D:\schet.xml' encoding 'UTF8';
copy (select table_to_xml('������',true , false ,'')) to 'D:\valuta.xml' encoding 'UTF8';
copy (select table_to_xml('����������_�����',true , false ,'')) to 'D:\card.xml' encoding 'UTF8';
copy (select table_to_xml('������',true , false ,'')) to 'D:\passwords.xml' encoding 'UTF8';
copy (select table_to_xml('��������',true , false ,'')) to 'D:\operations.xml' encoding 'UTF8';
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
INSERT INTO ������(id_�������,���,�������,��������,�����_��������,�����_��������)
  SELECT (xpath('//row/id_�������/text()', x))[1]::text::int AS id_�������,
         (xpath('//row/���/text()', x))[1]::text::varchar(30) AS ���,
         (xpath('//row/�������/text()', x))[1]::text::varchar(30) AS �������,
         (xpath('//row/��������/text()', x))[1]::text::varchar(30) AS ��������,
         (xpath('//row/�����_��������/text()', x))[1]::text::varchar(30) AS �����_��������,
         (xpath('//row/�����_��������/text()', x))[1]::text::varchar(30) AS �����_��������
  FROM unnest(xpath('//row', pg_read_file('D:\client.xml')::xml)) x;
end;
$$ language plpgsql;
select * from Import('D:\client.  xml');
drop function Import();


-----------------------------------------------------------------------------
select * from ������;
insert into ������(������������_������, ���_�����)  values ('BYN',1),('USD',1),('RUB',1);
drop table ������;
drop table �����;
drop table ����������_�����;
drop table ������;
drop table ��������;
drop table ��������;
drop table ���������;
drop table ������;
select * from ������;
select * from ���������;
select * from ��������;
select * from ������;
select * from ��������;
select * from �����;
select * from ����������_�����;
delete from ������ values where id_�������=14;
delete from �������� values where id_��������='2';
delete from ������ values where id_�������='6';
alter table ����������_����� alter column ���_����� type varchar(15);
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
  insert into ���������(���,�������,���������)
  values ('de'|| random_between(1,100000),'fef'|| random_between(1,100000),'jknj'|| random_between(1,100000));
  increm = increm + 1;
  exit when increm = 100000;
  end loop;
  end;
$$ language plpgsql;
call inser();

create user vlad password 'vlad';

create index For_Manager on ��������� using btree(id_���������);
drop index For_Manager;
create index For_Manager on ��������� using brin(id_���������);
delete from ������ where id_�������=16;

insert into ������(���,�������,��������,�����_��������,�����_��������)
values ('Vewf','ewf','fef','fwef','fweef');

select id_�����, ������������_������, �����
from ������
left join ����������_����� on ������.���_����� = ����������_�����.id_����� having �����>0::money
ORDER BY ����������_�����.id_����� Asc ;
