CREATE TABLE omp_sepo_properties (
  id NUMBER PRIMARY KEY,
  property_name VARCHAR2(100) NOT NULL UNIQUE,
  property_value VARCHAR2(100) NULL
);

INSERT INTO omp_sepo_properties
VALUES
(1, '������ �������', '1.0.0.2');

INSERT INTO omp_sepo_properties
VALUES
(2, '������ ��', '2018_02_07_v1');