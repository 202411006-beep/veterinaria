create database veterinaria;
use veterinaria;

-- ==========================
-- tablas principales
-- ==========================

create table cliente (
  id int auto_increment primary key,
  nombre varchar(100) not null,
  apellido varchar(100),
  direccion varchar(200),
  telefono varchar(50),
  email varchar(100)
) engine=innodb;



create table veterinario (
  id int auto_increment primary key,
  nombre varchar(100) not null,
  especialidad varchar(100),
  telefono varchar(50),
  email varchar(100),
  disponibilidad text
) engine=innodb;

create table mascota (
  id int auto_increment primary key,
  nombre varchar(100) not null,
  especie varchar(50),
  raza varchar(50),
  edad int,
  cliente_id int not null,
  foreign key (cliente_id) references cliente(id)
  );
  
create table expediente (
  id int auto_increment primary key,
  mascota_id int not null,
  notas text,
  foreign key (mascota_id) references mascota(id) 
  );

create table antecedente (
  id int auto_increment primary key,
  expediente_id int not null,
  tipo varchar(50),
  descripcion text,
  fecha date,
  foreign key (expediente_id) references expediente(id)
  );

create table control (
  id int auto_increment primary key,
  expediente_id int not null,
  fecha date,
  peso decimal(5,2),
  temperatura decimal(4,2),
  observaciones text,
  foreign key (expediente_id) references expediente(id) 
  );

create table medicamento (
  id int auto_increment primary key,
  nombre varchar(100) not null,
  stock int default 0,
  stock_min int default 0,
  precio decimal(10,2),
  fecha_vencimiento date
 );

create table producto (
  id int auto_increment primary key,
  nombre varchar(100) not null,
  descripcion text,
  precio decimal(10,2),
  stock int default 0,
  stock_min int default 0
 );

create table cita (
  id int auto_increment primary key,
  mascota_id int not null,
  cliente_id int not null,
  veterinario_id int not null,
  fecha datetime not null,
  estado enum('programada','atendida','cancelada','reprogramada') default 'programada',
  motivo text,
  foreign key (mascota_id) references mascota(id) on delete cascade,
  foreign key (cliente_id) references cliente(id) on delete cascade,
  foreign key (veterinario_id) references veterinario(id) on delete cascade
 );

create table consulta (
  id int auto_increment primary key,
  cita_id int,
  expediente_id int not null,
  veterinario_id int not null,
  diagnostico text,
  tratamiento text,
  observaciones text,
  costo decimal(10,2) default 0,
  foreign key (cita_id) references cita(id) on delete set null,
  foreign key (expediente_id) references expediente(id) on delete cascade,
  foreign key (veterinario_id) references veterinario(id) on delete cascade
 );

create table consulta_medicamento (
  id int auto_increment primary key,
  consulta_id int not null,
  medicamento_id int not null,
  cantidad int not null,
  foreign key (consulta_id) references consulta(id) on delete cascade,
  foreign key (medicamento_id) references medicamento(id) on delete cascade
 );

create table venta (
  id int auto_increment primary key,
  cliente_id int,
  fecha timestamp default current_timestamp,
  total decimal(10,2),
  metodo_pago enum('efectivo','tarjeta','transferencia') default 'efectivo',
  foreign key (cliente_id) references cliente(id) on delete set null
 );

create table venta_item (
  id int auto_increment primary key,
  venta_id int not null,
  producto_id int,
  medicamento_id int,
  cantidad int not null,
  precio decimal(10,2),
  foreign key (venta_id) references venta(id) on delete cascade,
  foreign key (producto_id) references producto(id) on delete set null,
  foreign key (medicamento_id) references medicamento(id) on delete set null
 );

-- ==========================
-- vistas simples
-- ==========================

create view v_consultas_por_veterinario as
select v.nombre as veterinario, count(c.id) as total_consultas, sum(c.costo) as total_ganado
from consulta c
join veterinario v on c.veterinario_id = v.id
group by v.id;

create view v_stock_medicamentos as
select nombre, stock, stock_min, fecha_vencimiento from medicamento;

create view v_clientes_mascotas as
select cl.nombre as cliente, m.nombre as mascota, m.especie, m.raza
from cliente cl
join mascota m on m.cliente_id = cl.id;


-- ==========================
-- triggers básicos
-- ==========================

delimiter $$
create trigger trg_consulta_medicamento after insert on consulta_medicamento
for each row
begin
  update medicamento set stock = greatest(0, stock - new.cantidad)
  where id = new.medicamento_id;
end$$
delimiter ;

delimiter $$
create trigger trg_venta_item after insert on venta_item
for each row
begin
  if new.producto_id is not null then
    update producto set stock = greatest(0, stock - new.cantidad)
    where id = new.producto_id;
  end if;
  if new.medicamento_id is not null then
    update medicamento set stock = greatest(0, stock - new.cantidad)
    where id = new.medicamento_id;
  end if;
end$$
delimiter ;

SHOW TRIGGERS;

SELECT trigger_schema, trigger_name, event_object_table, action_timing, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'veterinaria';
