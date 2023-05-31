use [MusicStore]

/* Q1: Who is the senior most employee based on job title? */

SELECT TOP 1 last_name, first_name, title
		FROM employee
		ORDER BY levels DESC;


/* Q2: Which countries have the most Invoices? */

SELECT COUNT(*) AS invoice_count, billing_country 
		FROM invoice
		GROUP BY billing_country
		ORDER BY invoice_count DESC;


/* Q3: What are top 3 values of total invoice? */

SELECT TOP 3 invoice_id, total
		FROM invoice
		ORDER BY total DESC;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT TOP 1 billing_city, SUM(total) invoice_total
		FROM invoice
		GROUP BY billing_city
		ORDER BY invoice_total DESC;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT TOP 1 C.customer_id, C.first_name, C.last_name, SUM(I.total) Total
		FROM customer C
		JOIN invoice I
		ON C.customer_id = I.customer_id
		GROUP BY C.customer_id, C.first_name, C.last_name
		ORDER BY TOTAL DESC;


/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT C.email, C.first_name, C.last_name
		FROM customer C
		JOIN invoice I ON C.customer_id = I.customer_id
		JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
		JOIN track T ON T.track_id = IL.track_id
		JOIN genre G ON G.genre_id = T.genre_id
		WHERE G.name = 'Rock'
		ORDER BY C.email;

/*Method 2*/

SELECT DISTINCT email,first_name, last_name
		FROM customer C
		JOIN invoice I ON C.customer_id = I.customer_id
		JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
		WHERE track_id IN(
						SELECT track_id FROM track T
						JOIN genre G ON T.genre_id = G.genre_id
						WHERE G.name LIKE 'Rock'
						)
						ORDER BY email;


/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT TOP 10 a.name, COUNT(a.artist_id) Count_artist
		FROM artist a
		JOIN album ab ON a.artist_id = ab.artist_id
		JOIN track t ON ab.album_id = t.album_id
		JOIN genre g ON t.genre_id = g.genre_id
		WHERE g.name = 'Rock'
		GROUP BY a.name
		ORDER BY COUNT(a.artist_id) DESC;


/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
	FROM track
	WHERE milliseconds > (
						SELECT AVG(milliseconds) AS avg_track_length
						FROM track )
						ORDER BY milliseconds DESC;


/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent 

Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

/*Method 1*/

SELECT CONCAT_WS(' ',c.first_name, c.last_name) cust_name, art.name artist_name, SUM(il.unit_price*il.quantity) total_spent
		FROM customer c
		JOIN invoice i ON c.customer_id = i.customer_id
		JOIN invoice_line il ON i.invoice_id = il.invoice_id
		JOIN track t ON t.track_id = il.track_id
		JOIN album a ON a.album_id = t.album_id
		JOIN artist art ON a.artist_id = art.artist_id
		GROUP BY c.first_name, c.last_name, art.name
		ORDER BY SUM(il.unit_price*quantity) DESC;

/*Method 2*/

WITH best_selling_artist AS 
(
	SELECT TOP 1 artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
		FROM invoice_line
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN album ON album.album_id = track.album_id
		JOIN artist ON artist.artist_id = album.artist_id
		GROUP BY artist.artist_id, artist.name
		ORDER BY SUM(invoice_line.unit_price*invoice_line.quantity) DESC
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
		FROM invoice i
		JOIN customer c ON c.customer_id = i.customer_id
		JOIN invoice_line il ON il.invoice_id = i.invoice_id
		JOIN track t ON t.track_id = il.track_id
		JOIN album alb ON alb.album_id = t.album_id
		JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
		GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
		ORDER BY SUM(il.unit_price*il.quantity) DESC;



/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1 */

WITH sales_per_country AS (
			SELECT COUNT(il.quantity) purchases, c.country,g.name
			FROM customer c
			JOIN invoice i ON c.customer_id = i.customer_id
			JOIN invoice_line il ON i.invoice_id = il.invoice_id
			JOIN track t ON t.track_id = il.track_id
			JOIn genre g ON t.genre_id = g.genre_id
			GROUP BY c.country,g.name),
max_genre_per_country AS (SELECT MAX(purchases) as max_purchases, country
						 FROM sales_per_country
						 GROUP BY country)
SELECT sales_per_country.*
		FROM sales_per_country
		JOIN max_genre_per_country
		ON sales_per_country.country = max_genre_per_country.country
		WHERE sales_per_country.purchases = max_genre_per_country.max_purchases
		ORDER BY sales_per_country.country ;

/* Method 2*/

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, 
		ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
		FROM invoice_line 
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY customer.country, genre.name
)
SELECT * FROM popular_genre WHERE RowNo <= 1;



/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/*Method 1*/

WITH customer_with_country AS (
			SELECT sum(total) as total_spent, first_name, last_name, billing_country
			FROM customer c
			JOIN invoice i ON c.customer_id=i.customer_id
			GROUP BY i.billing_country, c.first_name, c.last_name
            ),
country_max_spending AS (SELECT MAX(total_spent) AS max_spending, billing_country
					FROM customer_with_country
					group by billing_country)
SELECT cc.billing_country,cc.total_spent, cc.first_name, cc.last_name
		FROM customer_with_country cc
		JOIN country_max_spending ms
		ON cc.billing_country = ms.billing_country
		WHERE cc.total_spent = ms.max_spending
		ORDER BY cc.billing_country;


/*Methond 2*/

WITH customer_with_country as (
		SELECT i.billing_country, c.first_name, c.last_name, SUM(total) total_spent,
		ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY sum(total) DESC) AS rowno
		FROM invoice i
		JOIN customer c ON i.customer_id = c.customer_id
		GROUP BY i.billing_country, c.first_name, c.last_name
		)
SELECT * FROM customer_with_country WHERE rowno <= 1;

