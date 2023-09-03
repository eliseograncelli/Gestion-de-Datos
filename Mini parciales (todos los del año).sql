/* 304-1. Listar productos donde el precio unitario acordado sea menor al precio sugerido. 
Indicar, código, nombre y precio sugerido del producto, número de pedido, fecha de pedido, cantidad pedida, 
precio unitario acordado y la diferencia con el sugerido. 
Ordenar por nombre del producto alfabéticamente y diferencia de precios descendiente. */

SELECT pr.codigo, pr.nombre, pr.precio_sugerido, pe.numero, pe.fecha_pedido, 
sol.cantidad, sol.precio_unitario_acordado, pr.precio_sugerido - sol.precio_unitario_acordado Diferencia
FROM producto pr
INNER JOIN solicita sol ON sol.codigo_producto = pr.codigo
INNER JOIN pedido pe ON pe.numero = sol.numero_pedido
WHERE sol.precio_unitario_acordado < pr.precio_sugerido
ORDER BY pr.nombre ASC, diferencia DESC;


/* 304-1. Listar todos los productos que desarrolle un grupo 
(usar el nombre de algún grupo que hayan cargado) e indicar los pedidos de este mes (agosto) si los tuvo. 
Indicar código y nombre del producto y si hubo pedidos, número y fecha de pedido, cantidad pedida y precio convenido */

SELECT pr.numero_grupo, pr.codigo, pr.nombre, pe.numero, pe.fecha_pedido, sol.cantidad, sol.precio_unitario_acordado
FROM producto pr 
INNER JOIN solicita sol ON sol.codigo_producto = pr.codigo 
LEFT JOIN pedido pe ON pe.numero = sol.numero_pedido AND pe.fecha_pedido BETWEEN "2021-08-01" AND "2021-08-31"
WHERE pr.numero_grupo = 5
GROUP BY pr.numero_grupo, pr.codigo, pr.nombre, pe.numero, pe.fecha_pedido, sol.cantidad, sol.precio_unitario_acordado;


/* Se necesita evaluar los productos menos solicitados el año pasado, para analizar su próxima fabricación. 
Indicar por producto la cantidad de pedidos donde los han solicitado el año pasado. 
Mostrar aquellos que han sido solicitados en menos de 3 pedidos. 
Indicando código, nombre, característica, fecha del último pedido de 2020 y cantidad de pedidos. 
Si no existe ningún pedido en 2020, mostrar 0. */

SELECT pr.codigo, pr.nombre, pr.caracteristicas, MAX(pe.fecha_pedido), COUNT(pe.numero) cantPed
FROM producto pr
LEFT JOIN solicita sol ON sol.codigo_producto = pr.codigo
LEFT JOIN pedido pe ON pe.numero = sol.numero_pedido AND pe.fecha_pedido BETWEEN "2020-01-01" AND "2020-12-31"
GROUP BY pr.codigo, pr.nombre, pr.caracteristicas
HAVING cantPed < 3;


/* Listar los productos que entre sus materiales no se compongan de maní, nuez o almendra. Indicar código, nombre y precio sugerido */

SELECT pr.codigo, pr.nombre, pr.precio_sugerido
FROM producto pr 
WHERE pr.codigo NOT IN (
SELECT pr.codigo
FROM producto pr 
INNER JOIN composicion co ON co.codigo_producto = pr.codigo
INNER JOIN material ma ON ma.codigo = co.codigo_material
WHERE ma.nombre IN ("Mani", "Nuez", "Almendra"));


/* Listar los clientes y la cantidad de pedidos que han realizado. 
Incluir sólo los clientes que han realizado una cantidad mayor al 
promedio de dichas cantidades de todos los clientes. */

DROP TEMPORARY TABLE IF EXISTS cantidad;
CREATE TEMPORARY TABLE cantidad (
SELECT pe.cuil_cliente, COUNT(pe.numero) cant
FROM pedido pe
GROUP BY pe.cuil_cliente);

SELECT AVG(cant) INTO @prom
FROM cantidad;

SELECT cli.cuil, CONCAT(cli.nombre, " ", cli.apellido) "Nombre y Apellido", COUNT(pe.numero) pp
FROM cliente cli 
INNER JOIN pedido pe ON pe.cuil_cliente = cli.cuil
GROUP BY cli.cuil, "Nombre y apellido"
HAVING pp > @prom;


/* Realice las operaciones para aplicar los siguientes cambios dentro de una transacción. 
Se ha fabricado el día de hoy un nuevo lote del producto “bruscheta” que vence en 2 días. 
Debe insertarse con el número siguiente de lote y la cantidad fabricada es 50. 
Se debe además registrar 2 hs de Sanji Vinsmoke de trabajo de producción para dicho lote. 
También se deberá incrementar el precio sugerido un 20%. */

START TRANSACTION;

SELECT codigo INTO @bruscheta
FROM producto
WHERE nombre = "Bruscheta";

SELECT MAX(numero) INTO @lote
FROM lote
WHERE codigo_producto = @bruscheta;

INSERT INTO lote (codigo_producto, numero, cantidad_producida, fecha_produccion, fecha_vencimiento)
VALUE (@bruscheta, @lote + 1, 50, "2021-11-04", "2021-11-06");

SELECT MAX(numero) INTO @lote2
FROM lote
WHERE codigo_producto = @bruscheta;

SELECT cuil INTO @cuil
FROM miembro
WHERE nombre = "Sanji" AND apellido = "Vinsmoke";

INSERT INTO produce (codigo_producto, numero_lote, cuil_miembro, horas_trabajadas)
VALUE (@bruscheta, @lote2, @cuil, 2);

UPDATE producto
SET precio_sugerido = precio_sugerido * 1.2
WHERE codigo = @bruscheta;

COMMIT;
