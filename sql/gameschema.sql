CREATE SCHEMA game;
SET SCHEMA 'game';

CREATE DOMAIN base_bonus AS INTEGER
    DEFAULT 0
    CHECK (VALUE BETWEEN -6 AND 6);

CREATE DOMAIN main_attribute AS INTEGER
    DEFAULT 10
    CHECK (VALUE BETWEEN 3 AND 18);

CREATE DOMAIN classe_oggetto AS CHAR(4)
    DEFAULT NULL
    CHECK (VALUE IN ('_ATT', '_DIF', 'cons', 'cibo'));

CREATE TABLE utente (
    id      SERIAL PRIMARY KEY,
    email   TEXT UNIQUE NOT NULL,
    pw      CHAR(128) NOT NULL,
    nome    TEXT,
    CHECK (email LIKE '%@%.%')
);

CREATE TABLE sessione (
    chiave  CHAR(64) PRIMARY KEY,
    valore  JSON NOT NULL
);

CREATE TABLE lancio_dadi_attr (
    utente  INTEGER PRIMARY KEY REFERENCES utente(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    roll1   main_attribute NOT NULL,
    roll2   main_attribute NOT NULL,
    roll3   main_attribute NOT NULL,
    roll4   main_attribute NOT NULL,
    roll5   main_attribute NOT NULL
);

CREATE TABLE tipo_stanza (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    perc    DOUBLE PRECISION NOT NULL
);

CREATE TABLE nome_stanza (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    permesso_per INTEGER NOT NULL REFERENCES tipo_stanza(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE modif_stanza (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT
);

CREATE TABLE stanza (
    id      SERIAL PRIMARY KEY,
    finale  BOOLEAN NOT NULL,
    tipo    INTEGER NOT NULL REFERENCES tipo_stanza(id)
        ON UPDATE CASCADE,
    nome    INTEGER NOT NULL REFERENCES nome_stanza(id)
        ON UPDATE CASCADE,
    modif     INTEGER NOT NULL REFERENCES modif_stanza(id)
        ON UPDATE CASCADE
);

CREATE VIEW stanza_view AS (
    SELECT S.id, S.finale,
           T.nome AS nome_tipo, T.descr AS descr_tipo,
           N.nome as nome_proprio,
           M.nome AS nome_modif, M.descr AS descr_modif
    FROM stanza AS S JOIN tipo_stanza AS T ON S.tipo=T.id JOIN nome_stanza AS N ON S.nome=N.id JOIN modif_stanza AS M ON S.modif=M.id
);

CREATE TABLE connessa (
    stanza1 INTEGER NOT NULL REFERENCES stanza(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    stanza2 INTEGER NOT NULL REFERENCES stanza(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    visibile BOOLEAN NOT NULL,
    PRIMARY KEY (stanza1, stanza2),
    CHECK (stanza1 != stanza2)
);

CREATE TABLE tipo_nemico (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    min_ATT INTEGER NOT NULL,
    max_ATT INTEGER NOT NULL,
    min_DIF INTEGER NOT NULL,
    max_DIF INTEGER NOT NULL,
    min_PF  INTEGER NOT NULL,
    max_PF  INTEGER NOT NULL,
    min_danno INTEGER NOT NULL,
    max_danno INTEGER NOT NULL,
    min_monete INTEGER NOT NULL,
    max_monete INTEGER NOT NULL
);

CREATE TABLE ist_nemico (
    id      SERIAL PRIMARY KEY,
    _ATT    INTEGER NOT NULL,
    _DIF    INTEGER NOT NULL,
    _PFmax  INTEGER NOT NULL,
    _PFrim  INTEGER NOT NULL,
    _danno  INTEGER NOT NULL,
    monete INTEGER NOT NULL,
    in_stanza INTEGER NOT NULL REFERENCES stanza(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    tipo    INTEGER NOT NULL REFERENCES tipo_nemico(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE VIEW ist_nemico_view AS (
    SELECT I.id, T.nome, T.descr, I._ATT, I._DIF, I._PFmax, I._PFrim, I._danno, I.monete, I.in_stanza
    FROM ist_nemico AS I JOIN tipo_nemico AS T ON I.tipo=T.id
);

CREATE TABLE personaggio (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    _FOR    main_attribute NOT NULL,
    _INT    main_attribute NOT NULL,
    _AGI    main_attribute NOT NULL,
    _COS    main_attribute NOT NULL,
    ferite  INTEGER NOT NULL,
    monete  INTEGER NOT NULL,
    PE      INTEGER NOT NULL,
    prox_PE INTEGER NOT NULL,
    morto   BOOLEAN NOT NULL,
    creato_da INTEGER NOT NULL REFERENCES utente(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    in_stanza INTEGER REFERENCES stanza(id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE tipo_oggetto (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    _ATT    base_bonus NOT NULL,
    _DIF    base_bonus NOT NULL,
    _PER    base_bonus NOT NULL,
    _PF     base_bonus NOT NULL,
    _danno  INTEGER,
    classe  classe_oggetto,
    recupero_PF INTEGER,
    CHECK ((classe IS NOT DISTINCT FROM '_ATT' AND _danno IS NOT NULL AND _danno>0) OR (classe IS DISTINCT FROM '_ATT' AND _danno IS NULL)),
    CHECK ((classe IS NOT DISTINCT FROM 'cibo' AND recupero_PF IS NOT NULL AND recupero_PF>0) OR (classe IS DISTINCT FROM 'cibo' AND recupero_PF IS NULL))
);

CREATE TABLE car_oggetto (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    add_b_ATT INTEGER NOT NULL,
    add_b_DIF INTEGER NOT NULL,
    add_b_PER INTEGER NOT NULL,
    add_b_PF INTEGER NOT NULL,
    perc    DOUBLE PRECISION NOT NULL
);

CREATE TABLE rarita_oggetto (
    id      SERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    descr   TEXT,
    bonus   INTEGER NOT NULL,
    perc    DOUBLE PRECISION NOT NULL
);

CREATE TABLE ist_oggetto (
    id      SERIAL PRIMARY KEY,
    di_personaggio INTEGER REFERENCES personaggio(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    in_stanza INTEGER REFERENCES stanza(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    nascosto BOOLEAN,
    pr_vendita INTEGER,
    equip   BOOLEAN,
    consumato BOOLEAN,
    istanza_di INTEGER NOT NULL REFERENCES tipo_oggetto(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    car INTEGER REFERENCES car_oggetto(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    rarita  INTEGER REFERENCES rarita_oggetto(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CHECK ((di_personaggio IS NULL AND in_stanza IS NOT NULL) OR (di_personaggio IS NOT NULL AND in_stanza IS NULL)),
    CHECK (pr_vendita IS NULL OR di_personaggio IS NOT NULL),
    CHECK (nascosto IS NULL OR in_stanza IS NOT NULL)
);

CREATE OR REPLACE VIEW ist_oggetto_view AS (
    SELECT
        I.id, I.di_personaggio, I.in_stanza, I.nascosto, I.pr_vendita, I.equip, I.consumato, I.istanza_di, I.car, I.rarita,
        T.nome, T.descr, T.classe, T.recupero_PF,
        T._danno + COALESCE(R.bonus, 0) AS _danno,
        T._ATT + COALESCE(C.add_b_ATT, 0) + COALESCE(R.bonus, 0) AS _ATT,
        T._DIF + COALESCE(C.add_b_DIF, 0) + COALESCE(R.bonus, 0) AS _DIF,
        T._PER + COALESCE(C.add_b_PER, 0) + COALESCE(R.bonus, 0) AS _PER,
        T._PF + COALESCE(C.add_b_PF, 0)  + COALESCE(R.bonus, 0) AS _PF,
        C.nome AS nome_car, C.descr AS descr_car, R.nome AS nome_rarita, R.descr AS descr_rarita         
    FROM ist_oggetto AS I JOIN tipo_oggetto as T ON I.istanza_di=T.id
                          LEFT JOIN car_oggetto AS C ON I.car=C.id
                          LEFT JOIN rarita_oggetto AS R ON I.rarita=R.id
);

CREATE OR REPLACE VIEW ist_oggetto_view_no_nasc AS (
    SELECT * FROM ist_oggetto_view WHERE nascosto=false
);

CREATE OR REPLACE VIEW personaggio_attr_deriv AS (
    WITH bonus_zaino AS (
        SELECT di_personaggio, SUM(_ATT) AS b_ATT, SUM(_DIF) AS b_DIF, SUM(_PER) AS b_PER, SUM(_PF) AS b_PF, SUM(_danno) AS b_danno
        FROM ist_oggetto_view WHERE (equip=true OR equip IS NULL) AND (consumato=true OR consumato IS NULL) AND pr_vendita IS NULL GROUP BY di_personaggio
    )
    SELECT
        P.id,
        CAST(CEIL(((CAST ((P._FOR + P._AGI) AS DOUBLE PRECISION))/2)) + COALESCE(B.b_ATT, 0) AS INTEGER) AS _ATT,
        CAST(CEIL(((CAST ((P._COS + P._AGI) AS DOUBLE PRECISION))/2)) + COALESCE(B.b_DIF, 0) AS INTEGER) AS _DIF,
        P._INT + COALESCE(B.b_PER, 0) AS _PER,
        P._COS + COALESCE(B.b_PF, 0) AS _PFmax,
        P._COS + COALESCE(B.b_PF, 0) - P.ferite AS _PFrim,
        COALESCE(B.b_danno, 0) AS _danno
    FROM personaggio AS P LEFT JOIN bonus_zaino AS B ON P.id=B.di_personaggio
);
