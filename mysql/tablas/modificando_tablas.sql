-- MIGRACIÓN desde esquema actual sin eliminar tablas
-- Agrega categoria, enlaza producto → categoria y renombra nombreprod → nombreproducto.

-- PROCESO EJECUTADO PASO A PASO EN ESTE ORDEN:
-- 1. Recomendado mientras alteras estructura
SET FOREIGN_KEY_CHECKS = 0;

-- 2. Crear tabla categoria
CREATE TABLE IF NOT EXISTS categoria (
  idcategoria INT NOT NULL PRIMARY KEY,
  nombrecategoria VARCHAR(75) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Renombrar columna de producto
ALTER TABLE producto
  CHANGE nombreprod nombreproducto VARCHAR(50) NOT NULL;

-- 4. Agregar FK en producto hacia categoria
-- Primero como NULL para no romper filas existentes
ALTER TABLE producto
  ADD COLUMN categoria_idcategoria INT NULL AFTER valor,
  ADD INDEX idx_producto_categoria (categoria_idcategoria);

-- 5. Insertar categorías base
INSERT INTO categoria (idcategoria, nombrecategoria) VALUES
  (1,'General'),
  (2,'Periféricos'),
  (3,'Componentes'),
  (4,'Accesorios')
ON DUPLICATE KEY UPDATE nombrecategoria = VALUES(nombrecategoria);

-- 6. Mapeo automático por palabras clave del nombre del producto (usa 'nombreprod')
UPDATE producto
SET categoria_idcategoria = 2
WHERE categoria_idcategoria IS NULL
  AND LOWER(nombreproducto) REGEXP 'teclado|mouse|monitor|audifon|impresora|scanner';

UPDATE producto
SET categoria_idcategoria = 3
WHERE categoria_idcategoria IS NULL
  AND LOWER(nombreproducto) REGEXP 'procesador|cpu|placa|mother|ram|memoria|ssd|hdd|disco|gpu|video|tarjeta';

UPDATE producto
SET categoria_idcategoria = 4
WHERE categoria_idcategoria IS NULL
  AND LOWER(nombreproducto) REGEXP 'cable|funda|adaptador|hub|soporte|estuche|base|cargador';

-- 7. Lo que no matchee, va a 'General'
UPDATE producto
SET categoria_idcategoria = 1
WHERE categoria_idcategoria IS NULL;

-- 8. vuelve NOT NULL y crea la FK
ALTER TABLE producto
  ADD INDEX idx_producto_categoria (categoria_idcategoria);

ALTER TABLE producto
  MODIFY categoria_idcategoria INT NOT NULL,
  ADD CONSTRAINT producto_categoria_fk
    FOREIGN KEY (categoria_idcategoria)
    REFERENCES categoria(idcategoria)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

SET FOREIGN_KEY_CHECKS = 1;

-- 9. Comprobación rápida
SELECT idproducto, nombreproducto, categoria_idcategoria
FROM producto
ORDER BY idproducto;

-- 10. Índices en FKs existentes para rendimiento
ALTER TABLE ventas      ADD INDEX idx_ventas_cliente (clientes_idcliente);
ALTER TABLE detalleventa
  ADD INDEX idx_detalle_venta (ventas_idventa),
  ADD INDEX idx_detalle_producto (producto_idproducto);

SET FOREIGN_KEY_CHECKS = 1;