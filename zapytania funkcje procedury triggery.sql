================================================ F  U  N  K  C  J  E ================================================================================================



	drop function salary_three
	go
	create function salary_three (@identyfikator int) returns table as

	return (select employee_id, CONCAT(first_name, ' ', last_name) as employee, 
	salary, (3 * salary) as high_salary from employees 
	where employee_id = @identyfikator)

	go

	select * from salary_three(103) 




	drop function procent_oddziałow
	go
	create function procent_oddziałow(@kraj varchar(20)) returns NUMERIC(8,2) as 
	begin 
	DECLARE @ilosc FLOAT = (select COUNT(department_id) from departments)

	DECLARE @iloscwkraju FLOAT= (select COUNT(*) 
		from departments, countries, locations
		where departments.location_id = locations.location_id
		and locations.country_id=countries.country_id
		and countries.country_id=@kraj
		)

	return (@iloscwkraju/@ilosc)*100
	end 
	go

	select distinct countries.country_name, dbo.procent_oddziałow(country_id) as 'procent_oddziałow'
	FROM countries
	where dbo.procent_oddziałow(country_id) >0





======================================================= W  Y  Z  W  A  L  A  C  Z  E =========================================================================== 






	CREATE TRIGGER trig1
	ON JOBS
   	INSTEAD OF UPDATE
	AS 
	BEGIN
	declare curs cursor for  
		select job_id from inserted
	declare @job varchar(10)
	open curs
	fetch next from curs into @job
	while (@@FETCH_STATUS=0)
	begin
	declare @dodat as int = (select min_salary from inserted where job_id=@job ) - (select min_salary from jobs where job_id=@job)
	update employees set salary = salary + @dodat where job_id=@job
	update jobs set min_salary = (select min_salary from inserted where job_id=@job) + @dodat where job_id=@job
	fetch next from curs into @job
	end
	close curs
	deallocate curs
	END


--przykładowe polecenie uruchamiające 
  update jobs set min_salary=min_salary+999 where job_id='AD_VP' or job_id='AD_PRES'





select nazwisko, wynagrodzenie
from Pracownik, Stanowisko
where Pracownik.id_stanowiska=Stanowisko.id_stanowiska
and Pracownik.wynagrodzenie=Stanowisko.stawka_max
select * from Stanowisko

select * from Pracownik where id_stanowiska =102

update Stanowisko set stawka_max=6900 where id_stanowiska=102


	CREATE TRIGGER Salarychanges
   	 ON employees
    	INSTEAD OF UPDATE
    	AS
    	BEGIN
    	SET NOCOUNT ON
		declare @job varchar(10) = (select job_id from inserted)
		declare @pensjamin int = (select min_salary from jobs where job_id = @job)
		declare @pensjamax int = (select max_salary from jobs where job_id = @job)
		declare @pracownik varchar(20) = (select employee_id from inserted)
		declare @nowawartosc int = (select salary from inserted)


		if (@nowawartosc>@pensjamax)
		begin
		set @nowawartosc = @pensjamax
		update employees set salary = @nowawartosc where employee_id = @pracownik
		print'Zmodyfikowano wynagrodzenie do wartości maxymalnej dla pracownika: ' + @pracownik 
		end


		if (@nowawartosc<@pensjamin)
		begin
		set @nowawartosc = @pensjamin
		update employees set salary = @nowawartosc where employee_id = @pracownik
		print'Zmodyfikowano wynagrodzenie do wartości minimalnej dla pracownika: ' + @pracownik 
		end
	
		update employees set salary = @nowawartosc where employee_id = @pracownik


   	 END
	





	CREATE TRIGGER TRIG2
   	 ON employees
   	 INSTEAD OF UPDATE
    	 AS
   	 BEGIN
    	 SET NOCOUNT ON
		declare @pracownik varchar(20) = (select employee_id from inserted)
		declare @zmianacommision float = (select commission_pct from inserted)

		if (@zmianacommision > 0.5)
		begin 
		set @zmianacommision = 0.5
		update employees set commission_pct = @zmianacommision where employee_id=@pracownik
		print 'Zmodyfikowano prowizję do wartośc 0.5 dla pracownika ' + @pracownik
		end 

		update employees set commission_pct = @zmianacommision where employee_id=@pracownik


  	  END


--!!!!!!!!!!!!!!!!!!!!!!!!WERSJA Z KURSOREM


		CREATE TRIGGER TRIGGER2
   	 		ON employees
   			 INSTEAD OF UPDATE
    			 AS
   	 		BEGIN
				declare k cursor for 
				select employee_id from inserted
				declare @emp int
				open k
				fetch next from k into @emp
				while @@FETCH_STATUS=0
				begin
					declare @zmianacommision float = (select commission_pct from inserted where employee_id=@emp)
					if (@zmianacommision > 0.5)
					begin 
						set @zmianacommision = 0.5
						update employees set commission_pct = @zmianacommision where employee_id=@emp
						print 'Zmodyfikowano prowizję do wartośc 0.5 dla pracownika ' + CONVERT(VARCHAR,@emp)
					end 
					update employees set commission_pct = @zmianacommision where employee_id=@emp
					fetch next from k into @emp
				end
				close k
				deallocate k 

  	 		 END



	CREATE TRIGGER CountryAdd
   	 ON countries
   	 INSTEAD OF INSERT
    	AS
   	 BEGIN
   	 SET NOCOUNT ON
		declare @kraje varchar(20) = (select country_name from inserted)
		declare @idkraju varchar(20) = (select country_id from inserted)
		declare @idregionu varchar(20) = (select region_id from inserted)

		if (@kraje is null or @kraje = '')
		begin 
		set @kraje = 'Nowa nazwa'
		end 
		insert into countries (country_id, country_name, region_id) VALUES (@idkraju, @kraje, @idregionu)


  	  END



========================================= P  R  O   C  E  D  U  R  Y =====================================================================================



	drop procedure addCommisionPct
	go
	CREATE PROCEDURE addCommisionPct @dzial varchar(10), @prowizja float
	as 
	declare @licznik int 
	set @licznik =0 
	declare @pracownik varchar(20)
	begin 
	declare k cursor for 
	select employee_id
	from employees
	where commission_pct is NULL 
	and job_id=@dzial
	open k
	FETCH NEXT FROM k into @pracownik
	WHILE @@FETCH_STATUS =0
	begin
	update employees set commission_pct = @prowizja where employee_id=@pracownik
	set @licznik = @licznik +1
	FETCH NEXT FROM k into @pracownik
	end
	close k
	deallocate k
	if(@licznik >0)
	print 'Wprowadzono prowizję ' +convert(varchar,@licznik)+ ' pracownikom'
	if (@licznik =0)
	print 'Nie ma takich pracowników'
	end 
	go 

	exec addCommisionPct 'FI_ACCOUNT', 0.8




================================================ K  U  R  S  O  R  Y =======================================================================================


	declare @licznik int, @nazwa_dzialu varchar(15), @pracownicy varchar(40), @nazwa varchar(30)
	set @licznik =0
	set @nazwa_dzialu = 'SH_CLERK'
	declare k cursor for 
	select employees.last_name
	from employees, jobs
	where employees.salary=jobs.min_salary
	and employees.job_id=jobs.job_id
	and jobs.job_id = @nazwa_dzialu
	open k
	FETCH NEXT FROM k INTO @pracownicy
	WHILE @@FETCH_STATUS=0
	begin 
	set @licznik = @licznik+1
	print @pracownicy 
	FETCH NEXT FROM k INTO @pracownicy
	end 
	close k
	deallocate k
	if(@licznik>0)
	begin 
	print 'W oddziale ' + CONVERT(varchar,@nazwa_dzialu) +' miminalną płace ma '+ CONVERT(varchar,@licznik) +' pracowników'
	end 
	if(@licznik=0)
	begin 
	print 'Wszyscy pracownicy zarabiają wiecej niż minimum'
	end 







	declare @nroddzialu int, @listapracownikow varchar(30), @licznik int
	set @licznik =0
	set @nroddzialu =100

	declare k cursor for
	select last_name
	from employees
	where department_id =@nroddzialu

	open k
	FETCH NEXT FROM k INTO @listapracownikow
	WHILE @@FETCH_STATUS=0
	begin
	set @licznik = @licznik+1
	print @listapracownikow 
	FETCH NEXT FROM k INTO @listapracownikow
	end
	close k
	deallocate k

	if (@licznik>0)
	begin
	print 'Oddział zatrudnia '+CONVERT(varchar,@licznik)+' pracowników '
	end

	if(@licznik=0)
	begin 
	print 'Podany oddział nie zatrudnia pracowników'
	end 




	declare @imie varchar(20), @nazwisko varchar(20), @data datetime, @pensja int
	declare k cursor for 
	select first_name, last_name, hire_date, salary
	from employees
	where YEAR(GETDATE()) - YEAR(hire_date) > 25
	open k
	FETCH NEXT FROM k INTO @imie, @nazwisko, @data, @pensja
	WHILE @@FETCH_STATUS=0
	begin
	declare @dlugosc_pracy int
	set @dlugosc_pracy = YEAR(GETDATE()) - YEAR(@data)
	declare @obliczona_pensja int 
	if(@pensja < 10000)
	set @obliczona_pensja = @pensja * 1.15 
	if(@pensja>=10000 and @pensja<=20000)
	set @obliczona_pensja = @pensja * 1.10
	if(@pensja > 20000)
	set @obliczona_pensja = @pensja * 1.05
	declare @obliczona_podwyzka int
	set @obliczona_podwyzka = @obliczona_pensja - @pensja

	print 'Pracownikowi ' + @imie + ' '+@nazwisko +' zatrudnionemu od ' + convert(varchar,@dlugosc_pracy) + 
	' lat, należy się podwyżka w wysokości ' + convert(varchar,@obliczona_podwyzka)
	FETCH NEXT FROM k INTO @imie, @nazwisko, @data, @pensja
	end
	close k
	deallocate k 







	declare @nazwastanowiska varchar(10), @pensja int, @licznik int
	set @pensja = 1000
	set @licznik =0

	declare k cursor for 
	select distinct job_id 
	from employees
	where salary > @pensja
	open k
	FETCH NEXT FROM k INTO @nazwastanowiska
	WHILE @@FETCH_STATUS=0
	begin
	set @licznik = @licznik +1
	print @nazwastanowiska
	FETCH NEXT FROM k INTO @nazwastanowiska
	end
	close k
	deallocate k

	if(@licznik =0)
	print'Na żadnym stanowisko nie zarabia się tak dużo '

	if(@licznik>0)
	print 'Więcej zarabia się na ' + convert(varchar, @licznik) + ' stanowiskach'




---Podaj nazwy działów w których sa zatrudnieni pracownicy nie mający prowizji. 
  	select  departments.department_name
 	 from departments, employees
 	 where departments.department_id=employees.department_id
 	 and employees.commission_pct is null
 	 group by departments.department_name




--Jakie stanowisko zajmował pierwszy zatrudniony pracownik(na podstawie tabeli employees)

 	 select top 1 jobs.job_title
 	 from employees,jobs
 	 where employees.job_id=jobs.job_id
 	 order by employees.hire_date asc


--Podaj nazwę miasta (z tabeli locations), w którym znajduje sie oddział firmy(departments) ale nie ma
  tam zatrudnionych pracowników

 	 select distinct locations.city
 	 from locations, departments
 	 where locations.location_id=departments.location_id
 	 and (select count(*) from employees where employees.department_id = departments.department_id 
 	 ) =0



--Podaj nazwiska pracowników ,którzy pracują na stanowisku o najmniejszych widełkach płacowych oraz podaj nazwiska ich szefów



  	select employees.last_name, (select top 1 (j.max_salary-j.min_salary)) as roznica, 
  	(select emp1.last_name from employees emp1 where employees.manager_id=emp1.employee_id) as szef
  	from employees, jobs j
 	 where employees.job_id=j.job_id
 	 and j.max_salary-j.min_salary = (select top 1 (j1.max_salary-j1.min_salary) as r1 from jobs j1 order by r1)
 	 order by roznica asc 




--Nazwy działów i srednie zarobki ich pracowników. Malejaca wedlug zarobkow

	select distinct departments.department_name,
	(select  avg(employees.salary) from employees where employees.department_id=departments.department_id 
	 ) as srednia
	from departments
	where (select  avg(employees.salary) from employees where employees.department_id=departments.department_id 
	 ) is not null
	order by srednia desc



--Wyswietl imiona i nazwiska tych pracowników, których kierownik ma najwięcej podwładnych. Posortuj alfabetycznie

	select employees.first_name, employees.last_name
	from employees
	where employees.manager_id= (select top 1 B.manager_id
	from employees B
	order by (select count(*) from employees a where a.manager_id=B.manager_id) desc ) 
	order by employees.first_name, employees.last_name





--Podaj imiona i nazwiska pracowników, którzy wcześniej pracowali w tych samych oddziałach

	select distinct employees.first_name, employees.last_name, employees.employee_id
	from employees, job_history
	where employees.employee_id=job_history.employee_id
	and job_history.department_id=employees.department_id



--Podaj nazwy oddziałów, w których są zatrudnieni pracownicy nie mający prowizji
	select distinct departments.department_name
	from departments, employees
	where departments.department_id=employees.department_id
	and employees.commission_pct is null 




--Podaj nazwy stanowisk, z których nikt nie został zwolniony (nie ma wpisów w job_history.) Wynik posotrować rosnąco

	select jobs.job_title
	from jobs
	where (select count(*) from job_history where job_history.job_id=jobs.job_id)=0


--Podaj nazwy krajów oraz znajdujących się w nich oddziałów 

	select distinct countries.country_name, departments.department_name
	from countries, departments, locations
	where countries.country_id=locations.country_id
	and locations.location_id=departments.location_id
	group by countries.country_name, departments.department_name


--Podaj nazwy krajów oraz liczbę znajdujących się w nich oddziałów 

	select distinct countries.country_name, count(*)
	from countries, locations, departments
	where countries.country_id=locations.country_id
	and locations.location_id=departments.location_id
	group by countries.country_name



--Wypisz zarobki wszystkich pracownikow z miasta Toronto i wszystkich pracownikow z Oxfordu
	select locations.city, employees.first_name, employees.salary
	from locations, employees, departments
	where employees.department_id=departments.department_id
	and departments.location_id=locations.location_id
	and (locations.city='Toronto' or locations.city='Oxford')



--Podaj nazwiska i zarobki tych pracownikow, których wynagrodzenie jest mniejsze niż 25% wynagrodzenia szefa

	select employees.last_name, employees.salary
	from employees
	where employees.salary <0.25*(select e.salary from employees e where e.employee_id=employees.manager_id)

--Podaj nazwiska imiona i wynagrodzenia preacownikow ktorych szefowie zarabiają więcej niż 90% maksymalnej stawki na swoim stanowisku

	select employees.first_name, employees.last_name, employees.salary
	from employees
	where (select e1.salary from employees e1 where e1.employee_id=employees.manager_id ) 
	> 0.9*(select top 1 jobs.max_salary from jobs, employees e2 where e2.job_id = jobs.job_id and e2.employee_id=employees.manager_id)
	order by employees.salary




 	select e.first_name, e.last_name, e.salary
 	from employees e, employees e1
 	where e.manager_id=e1.employee_id
 	and e1.salary > 0.9 * (select jobs.max_salary from jobs where jobs.job_id=e1.job_id)
 	order by e.salary


========================================================================================================


--Sprawdź ilu pracownikow przepracowało mniej niż 6msc z roku swojego zatrudnienia

	select count(*)
	from employees
	where MONTH(employees.hire_date) < 6


--Jakie stanowisko zajmował pierwszy zatrudniony pracownik

	select top 1 jobs.job_title
	from jobs, employees
	where jobs.job_id=employees.job_id
	and employees.hire_date = (select top 1 employees.hire_date order by hire_date asc)


--Podaj nazwe pańswt europeskich w których nie ma siedziny żaden oddział

	select country_name
	from countries,regions
	where countries.region_id=regions.region_id
	and regions.region_name = 'Europe' 
	and ( select count(*) from locations where locations.country_id=countries.country_id )=0



--Podaj nazwy miast, w których nie ma działów. Wynik posortuj rosnąco według miast. 
	select locations.city
	from locations
	where (select count(*) from departments where departments.location_id=locations.location_id)=0
	order by locations.city asc


--Podaj nazwy stanowisk, z których nikt nie został zwolniony( nie ma wpisów w job_history). Wynik posortować rosnąco

	select jobs.job_title
	from jobs
	where jobs.job_id not in (select job_history.job_id from job_history)



--Nazwiska pracowników którzy pracowali przynajmniej na jednym takim stanowisku, na jakim pracował Whalen (job_history)

	select employees.last_name
	from employees
	where employees.job_id IN (select job_history.job_id from job_history,employees e 
				   where e.employee_id=job_history.employee_id and e.last_name='Whalen') 
	and employees.last_name<>'Whalen'



--Wyświetl nazwiska (last_name), imiona (first_name) i wynagrodzenia tych pracowników, którzy zarabiają najniższą stawkę na danym stanowisku (dane stanowisk w tabeli jobs)

	select employees.last_name, employees.first_name, jobs.min_salary
	from employees, jobs
	where employees.job_id=jobs.job_id
	and employees.salary=jobs.min_salary


	select employees.last_name, employees.first_name, employees.salary, jobs.job_title
	from employees, jobs
	where employees.job_id=jobs.job_id
	and employees.salary=(select top 1 e.salary from employees e where e.job_id=employees.job_id order by e.salary asc)




--Podaj nazwy odddzialow w ktorych sa zatrudnieni pracownicy nie majacy pensji.
	
	select departments.department_name
	from departments, employees
	where departments.department_id=employees.department_id
	and employees.salary=0



--Jakie stanowisko zajmował pierwszy zatrudniony pracownik

	select top 1 jobs.job_title
	from jobs, employees
	where jobs.job_id=employees.job_id
	order by employees.hire_date asc



--Podaj nazwiska oraz liczbę podwładnych dla tych managerów którzy ich mają więcej niz 10 lub mniej niż 5


	select e1.last_name, count(e.employee_id) as ile
	from employees e1, employees e
	where e1.employee_id=e.manager_id
	group by e1.last_name
	having count(e.employee_id) > 10
	or count(e.employee_id) < 5 
	order by ile desc

	select e.last_name, 
	(select count(employees.employee_id) from employees where e.employee_id=employees.manager_id)
	from employees e
	where (select count(employees.employee_id) from employees where e.employee_id=employees.manager_id) > 10
	or
	(select count(employees.employee_id) from employees where e.employee_id=employees.manager_id)<5
	and (select count(employees.employee_id) from employees where e.employee_id=employees.manager_id) <> 0



---Podaj nazwy działów w których sa zatrudnieni pracownicy nie mający prowizji. 
  	select  departments.department_name
 	 from departments, employees
 	 where departments.department_id=employees.department_id
 	 and employees.commission_pct is null
 	 group by departments.department_name




--Jakie stanowisko zajmował pierwszy zatrudniony pracownik(na podstawie tabeli employees)

 	 select top 1 jobs.job_title
 	 from employees,jobs
 	 where employees.job_id=jobs.job_id
 	 order by employees.hire_date asc


--Podaj nazwę miasta (z tabeli locations), w którym znajduje sie oddział firmy(departments) ale nie ma
  tam zatrudnionych pracowników

 	 select distinct locations.city
 	 from locations, departments
 	 where locations.location_id=departments.location_id
 	 and (select count(*) from employees where employees.department_id = departments.department_id 
 	 ) =0

--Nazwe miasta w ktorym znajduje sie oddzial firmy, ale nie ma zatrudnionch pracownikow

	select distinct locations.city
	from locations, departments
	where locations.location_id=departments.location_id
	and (select count(*) from employees where employees.department_id=departments.department_id)
	=0



--Podaj nazwiska pracowników ,którzy pracują na stanowisku o najmniejszych widełkach płacowych oraz podaj nazwiska ich szefów



  	select employees.last_name, (select top 1 (j.max_salary-j.min_salary)) as roznica, 
  	(select emp1.last_name from employees emp1 where employees.manager_id=emp1.employee_id) as szef
  	from employees, jobs j
 	 where employees.job_id=j.job_id
 	 and j.max_salary-j.min_salary = (select top 1 (j1.max_salary-j1.min_salary) as r1 from jobs j1 order by r1)
 	 order by roznica asc 


	select employees.last_name, jobs.job_title, (select e.last_name from employees e where employees.manager_id=e.employee_id)
	from employees, jobs
	where employees.job_id=jobs.job_id
	and (jobs.max_salary-jobs.min_salary) = 
	(select top 1 (j.max_salary-j.min_salary) mini from jobs j order by mini )




--Dla każdego pracownika wyświetl jego nazwisko (last_name), datę zatrudnienia (hire_date) oraz datę jego podwyżki. Data podwyżki (z etykietą kiedy) to pierwszy poniedziałek po sześciu miesiącach pracy



 	SELECT last_name, hire_date,
CASE   
         WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=1 THEN DATEADD(mm,6,hire_date)+1
         WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=2 THEN DATEADD(mm,6,hire_date)
	 WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=3 THEN DATEADD(mm,6,hire_date)+6
	 WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=4 THEN DATEADD(mm,6,hire_date)+5
	 WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=5 THEN DATEADD(mm,6,hire_date)+4
	 WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=6 THEN DATEADD(mm,6,hire_date)+3
	 WHEN DATEPART(dw,DATEADD(mm,6,hire_date))=7 THEN DATEADD(mm,6,hire_date)+2
END as kiedy
from employees



--Ilu pracowników zatrudniono na stanowiskach nie zawierających słów sales i clerk. Wynik posortować malejąco według liczby pracowników. 

	select jobs.job_title, count(*) as ile
	from employees, jobs
	where employees.job_id=jobs.job_id
	and jobs.job_title not in (select j.job_title from jobs j where j.job_title like '%clerk%' or j.job_title like '%sales%' )
	group by jobs.job_title
	order by ile desc


--Podaj imiona i nazwiska pracowników którzy mają a i e w nazwisku. Wynik nazwij pracownicy i przedstaw w postaci jednego ciągu Np Jan Kowalski

	select CONCAT(employees.first_name,' ', employees.last_name)
	from employees
	where (employees.last_name like '%a%' and employees.last_name like '%e%')


--Ilu pracowników ma w numerze telefonu przynajmnie 3 razy cyfre 6 

	select phone_number, len(phone_number)-len(replace(phone_number,'6',''))
	from employees
	where (len(phone_number)-len(replace(phone_number,'6',''))) >=3 

	select employees.phone_number
	from employees
	where employees.phone_number like '%6%6%6%'



--Podaj nazwy tych krajów których identyfikator stanowią dwie pierwsze litery z nazwy kraju

	select countries.country_name
	from countries
	where SUBSTRING(countries.country_name, 1,2)=SUBSTRING(countries.country_id, 1,2)



--Wyświetl nazwiska i daty zatrudnienia pracowników, którzy pracuja dłużej niż wynosi średnia długośc zatrudnienia w firmie


	select employees.last_name, employees.hire_date
	from employees
	where 
	DATEDIFF(mm, employees.hire_date, getdate()) > (select AVG(DATEDIFF(mm, e.hire_date, getdate())) from employees e)




--Wyświetl nazwiska pracowników których współpracownicy (przynajmniej jeden) z działu pracują krócej i zarabiają więcej 



	select distinct e.employee_id, e.last_name
	from employees e, employees d
	where
	e.department_id=d.department_id
	and 
	(DATEDIFF(mm, e.hire_date, getdate()) > DATEDIFF(mm, d.hire_date, getdate()) )
	and 
	(e.salary < d.salary)
	order by e.last_name



--Wyświetl nazwy tych oddziałów, w których są pracownicy zarabiający mniej niż połowa średniej płacy w firmie


	select distinct departments.department_name
	from departments, employees
	where departments.department_id=employees.department_id
	and 
	employees.salary < 0.5 * (select avg(e.salary) from employees e ) 




--Wyświetl identyfikatory oddziałów (department_id), nazwy oddziałów (department_name) i liczbę pracowników, dla tych oddziałów dla których ta liczba jest najmniejsza 


	select departments.department_id, departments.department_name, 
	(select count(*) from employees where employees.department_id=departments.department_id ) as ile
	from departments
	where (select count(*) from employees where employees.department_id=departments.department_id ) = 
	( 
	select  top 1
	(select count(*) from employees e2 where e2.department_id=d2.department_id ) as ile2
	from departments d2
	where (select count(*) from employees e2 where e2.department_id=d2.department_id ) > 0
	order by ile2
	)
	order by ile asc





	select departments.department_id, departments.department_name, 
	(select count(employees.employee_id) from employees where employees.department_id=departments.department_id  ) as ile
	from departments
	where (select count(employees.employee_id) from employees where employees.department_id=departments.department_id  ) > 0
	and 
	(select count(employees.employee_id) from employees where employees.department_id=departments.department_id  ) = 
	(
	select top 1 (select count(e1.employee_id) from employees e1 where e1.department_id=d2.department_id  )
	from departments d2
	where (select count(e1.employee_id) from employees e1 where e1.department_id=d2.department_id  ) > 0
	order by (select count(e1.employee_id) from employees e1 where e1.department_id=d2.department_id  ) asc
	)




--Podac pary numerów pracowników p1 p2 takich że p2 jest zwierzchnikiem p1 oraz różnice ich zarobków. Uwzględnic tylko pośrednie zależności


	select employees.employee_id as p1, (select e1.employee_id from employees e1 where employees.manager_id=e1.employee_id) as p2, 
	((select e1.salary from employees e1 where employees.manager_id=e1.employee_id) - employees.salary) as roznica_pensji
	from employees

	select employees.employee_id as p1 , (select e.employee_id from employees e where e.employee_id=employees.manager_id) as p2, 
	(select (e1.salary-employees.salary) from employees e1 where e1.employee_id=employees.manager_id) as salary_difference
	from employees



-- Podaj zarobki i nazwiska pracowników od litery P do U (włącznie) którzy zarabiają nie mniej niż średnia bezpośrednich podwładnych pracowników 101 i 103


	select employees.salary, employees.last_name
	from employees
	where employees.salary >= (select AVG(e1.salary) from employees e1, employees e2 where e1.manager_id=e2.employee_id and 
	e2.employee_id in ('101', '103'))
	and SUBSTRING(employees.last_name, 1,1) >= 'P' and SUBSTRING(employees.last_name, 1,1) <= 'U'





--Podać numery pracowników zatrudnionych na stanowisku o płacy maksymalnej większej niż 10000 którzy mają wszystkie umiejętności (SKILL) o randze równej 5 



	select employees.employee_id, Skill.Ranga,count(*)
	from employees, jobs, Skemp, Skill
	where employees.job_id=jobs.job_id
	and employees.employee_id=Skemp.Employee_ID
	and Skemp.S_ID=Skill.S_ID
	and jobs.max_salary>10000
	--and Skill.Ranga = 5
	and ( select count(*) from Skill sl2,Skemp sk2 where sl2.S_ID=sk2.S_ID and sk2.Employee_ID=employees.employee_id and sl2.Ranga=5 )>0
	and ( select count(*) from Skill sl2,Skemp sk2 where sl2.S_ID=sk2.S_ID and sk2.Employee_ID=employees.employee_id and sl2.Ranga<>5 )=0
	group by employees.employee_id, Skill.Ranga



-------------------------------------------------------------------------------------------------------------------------

--Wyswietl nazwisko,stanowisko oraz wysokosc pensji pracownika, ktorzy nie pracuja
  na stanowisku zaczynajacym sie na litere s ani na zadnym ze stanowisk posiadajacych 
  w swojej nazwie litere d oraz ktorych zarobki nie naleza do przedzialu od 2600 do 11000.
  Wyswietlane dane uporzadkuj rosnaco wedlug kolejnosci wysokosci pensji



 	select employees.last_name, employees.salary, jobs.job_title
 	from employees, jobs
 	where employees.job_id=jobs.job_id
 	and jobs.job_title not like 's%'
 	and jobs.job_title not like '%d%'
 	and employees.salary not between 2600 and 11000
 	order by employees.salary asc




--Ilu pracownikow podlega managerom posiadajacych identyfikatory z przedzialu:[100,107] a ilu nie przypisano manegara. Wyniki posortuj malejaco w zaleznosci od liczby pracownikow

 	(select count(e.employee_id)  as Manager_100_107 from employees e, employees e1 where 
 	e.manager_id=e1.employee_id and e1.employee_id >=100 and e1.employee_id<=107 )

 
  	(select count(e.employee_id)  as Manager_lack from employees e where e.manager_id is NULL  )



--Ilu pracownikow zatrudniono w latach 1997-1999 na poszczegolnych stanowiskach nie zawierajacych w nazwie slowa 'Clerk'. Dane posortuj malejaco wedlug liczby zatrudnionych pracownikow


 	select count(employees.employee_id) as ile, jobs.job_title
 	from employees, jobs
 	where YEAR(employees.hire_date) BETWEEN 1997 and 1999
 	and employees.job_id=jobs.job_id
 	and jobs.job_title not like '%clerk%'
 	group by jobs.job_title
 	order by ile desc



--Wypisz miasta z Azji, dla ktorych nie okreslono 'state_province'

	select locations.city
	from locations, countries, regions
	where regions.region_id=countries.region_id
	and countries.country_id=locations.country_id
	and locations.state_province is NULL
	and regions.region_name = 'Asia'




--Podaj nazwy oddzialow oraz kwoty jakie kazdy z oddzialow wydaje na pensje swoich pracownikow (wypisac 5 oddzialow, ktore wydaja najwiecej)

 	select top 5 departments.department_name, (select SUM(employees.salary) from employees where employees.department_id=departments.department_id) as kwota
 	from departments
 	order by kwota desc



--Wyswietl nazwy krajow, miasta oraz liczbe departamentow w danym kraju i miescie. Zapytanie powinno uwzglednic tylko te panstwa i miasta, ktore posiadaja depertament

 	select countries.country_name, locations.city, (select count(departments.department_id) from departments where
 	departments.location_id=locations.location_id and locations.country_id=countries.country_id)
 	from countries, locations
 	where countries.country_id=locations.country_id
 	and (select count(departments.department_id) from departments where
 	departments.location_id=locations.location_id and locations.country_id=countries.country_id) <> 0






--Wyswietl tylko te oddzialy (department), ktore zatrudniaja pracownikow, ktorych zarobki nie przekraczaja 50% srednich zarobkow (wszystkich pracownikow)

 	select distinct departments.department_name 
 	from departments, employees
 	where departments.department_id=employees.department_id
 	and employees.salary < 0.5 * (select AVG(e.salary) from employees e)





--Wyswietl nazwiska(last_name), imiona(first_name) i wynagrodzenie tych pracownikow, ktorzy zarabiaja najnizsza stawke na danym stanowisku(dane stanowisk w tabeli jobs).


 	select employees.last_name, employees.first_name, employees.salary, jobs.job_title
 	from employees, jobs
 	where employees.job_id=jobs.job_id
 	and employees.salary = jobs.min_salary




--Podaj nazwy dzialow zatrudniajacych wiecej niz 10 pracownikow


	select distinct departments.department_name, count(*)
	from departments, employees
	where departments.department_id=employees.department_id
	group by departments.department_name
	having count(*)> 10 



--Podać pary działów (department_id) d1, d2 takich że w dziale d1 jest zatrudniony pracownik którego wynagrodzenie jest równe wynagrodzeniu przynajmniej jednego pracownika zatrudnionego w d2


	select distinct e1.department_id, 
	(select top 1 e2.department_id from employees e2
	where e1.salary=e2.salary
	and e1.department_id<>e2.department_id
	and e1.department_id<e2.department_id
	)
	from employees e1
	where e1.department_id is not null
	and 
	(select top 1 e2.department_id from employees e2
	where e1.salary=e2.salary
	and e1.department_id<>e2.department_id
	and e1.department_id<e2.department_id
	) is not null
	order by e1.department_id asc 



--Podać pary numerów pracowników p1 p2 takich że p2 jest zwierzchnikiem p1

	select e1.employee_id as p1, e2.employee_id as p2
	from employees e1, employees e2
	where e1.manager_id=e2.employee_id




--Ilu pracowników podlega bezpośrednio pracownikom o identyfikatorach większych niż 100 i mniejszych niż 110 lub którym nie przypisano bezpośredniego zwierzchnika. Wynik posortuj malejąco
--w zależności od liczby pracowników


	select count(e1.employee_id) 
	from employees e1
	where e1.manager_id between 100 and 110 
	or e1.manager_id is null




--Podaj miasta i prowincje(state_province), ktorych pierwsza litera nazwy miasta i prowincji sa takie same. Posortuj wyniki rosnaco wedlug miasta i prowincji

	select locations.city, locations.state_province
	from locations
	where SUBSTRING(locations.city, 1, 1) = SUBSTRING(locations.state_province, 1, 1)
	order by locations.city, locations.state_province desc


--Podaj nazwę działu pracowników, których numer telefonu składa się z osiemnastu pozycji 



	select departments.department_name
	from departments, employees
	where departments.department_id=employees.department_id
	and LEN(employees.phone_number)=18
	group by departments.department_name



--Podaj imiona i nazwiska oraz daty zatrudnienia pracowników, którzy zostali zatrudnieni w dniu tygodnia w którym było najwięcej zatrudnień


	select employees.first_name, employees.last_name, employees.hire_date
	from employees
	where DATEPART(dw, employees.hire_date) =
	(select top 1 (DATEPART(dw, employees.hire_date))
	from employees
	group by (DATEPART(dw, employees.hire_date))
	order by count(DATEPART(dw, employees.hire_date)) desc)






TWORZENIE TABEL 
	create table SKILL (
	S_ID int NOT NULL PRIMARY KEY, 
	Name varchar(20), 
	Ranga int, 

	)


	create table SKEMP (
	S_ID int, 
	Employee_ID int,
	PRIMARY KEY (S_ID, Employee_ID),
	FOREIGN KEY (S_ID) references SKILL(S_ID), 
	FOREIGN KEY (Employee_ID) references employees(employee_id), 
	)







