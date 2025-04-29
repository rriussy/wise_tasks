Database: pagila

SELECT *
FROM pg_catalog.pg_tables
WHERE schemaname != 'pg_catalog' AND
    schemaname != 'information_schema';

select * from country;

select * from category;
select * from film;
select * from film_category;


--1
select category.name, count(film.film_id)  from category
left join film_category on category.category_id = film_category.category_id
left join film on film.film_id =film_category.film_id
group by category.name
order by count(film.film_id) DESC;



--2
select actor.actor_id, actor.first_name ||' '|| actor.last_name, sum(film_rental_count.rental_count) as rental_count
from actor
left join film_actor on film_actor.actor_id = actor.actor_id
left join 
	(select film.film_id as film_id, count(rental_id) as rental_count  from film
	left join inventory on inventory.film_id = film.film_id
	left join rental on rental.inventory_id = inventory.inventory_id
	group by film.film_id) as film_rental_count
on film_actor.film_id = film_rental_count.film_id
group by actor.actor_id
order by sum(film_rental_count.rental_count) desc
limit 10;

--3
select category.name, sum(film_revenue.revenue) as total_rev from category
left join film_category on film_category.category_id = category.category_id
left join
	(select film.film_id as film_id, film.rental_rate * count(rental_id) as revenue  from film
	left join inventory on inventory.film_id = film.film_id
	left join rental on rental.inventory_id = inventory.inventory_id
	group by film.film_id) as film_revenue
on film_category.film_id = film_revenue.film_id
group by category.name
order by total_rev desc
limit 1;

--4 
select title from film
left join inventory on film.film_id = inventory.film_id
where inventory_id is null;

--5
with actor_rank as
(select actor.actor_id,actor.first_name,actor.last_name, dense_rank() over(order by count(children_films.film_id) DESC) as rn
from (select film.film_id from film
	left join film_category  on film.film_id =film_category.film_id
	left join category on category.category_id = film_category.category_id
	where category.name = 'Children') as children_films
left join film_actor on film_actor.film_id = children_films.film_id
left join actor on actor.actor_id = film_actor.actor_id
group by actor.actor_id)
select * from actor_rank
where rn < 4;


-- 6
select city.city_id, city.city, count(customer.active) filter(WHERE customer.active = 1) as act,count(customer.active) filter(WHERE customer.active != 1) as inact
from city
left join address on address.city_id = city.city_id
left join customer on customer.address_id = address.address_id
group by city.city_id
order by inact DESC;

--7
select category.category_id, category.name, sum(inv_rent.rent_duration) as total_rent
from category
left join film_category on category.category_id = film_category.category_id
left join film on film_category.film_id = film.film_id
left join inventory on film.film_id = inventory.film_id
left join
	(select rental_info.inventory_id, rental_info.rent_duration from
		(select rental.rental_id, rental.inventory_id, rental.customer_id, rental.return_date - rental.rental_date as rent_duration, city.city_id 
		from rental 
		inner join staff on staff.staff_id = rental.staff_id
		inner join store on staff.store_id = store.store_id
		inner join address on store.address_id = address.address_id
		inner join city on address.city_id = city.city_id) as rental_info
	inner join
		(select customer.customer_id, city.city_id, city.city
		from customer 
		inner join address on customer.address_id = address.address_id
		inner join city on city.city_id = address.city_id) as customer_cities
		on rental_info.customer_id = customer_cities.customer_id
		--where customer_cities.city_id = rental_info.city_id and left(customer_cities.city,1) = 'A'
		where left(customer_cities.city,1) = 'A'
	) as inv_rent
on inventory.inventory_id = inv_rent.inventory_id
group by category.category_id
order by total_rent desc
limit 1;


-- no films rent in such cities
select film.film_id, sum(rental.return_date - rental.rental_date)
from film
left join inventory on inventory.film_id = film.film_id
left join rental on inventory.inventory_id = rental.inventory_id
left join staff on staff.staff_id = rental.staff_id
left join store on staff.store_id = store.store_id
left join address on store.address_id = address.address_id
left join city on address.city_id = city.city_id
where LENGTH(city.city) != LENGTH(REPLACE(city.city, '-',''))
group by film.film_id
;
