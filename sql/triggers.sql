--Controllo che il numero di oggetti nello zaino di un personaggio non superi ceil(_cos/2), se prova ad andare oltre annullo l'operazione
CREATE OR REPLACE FUNCTION funzione_capacita_zaino()
    RETURNS TRIGGER
AS $$
from math import ceil
if TD["new"]["di_personaggio"] is not None and (TD["old"] is None or TD["new"]["di_personaggio"]!=TD["old"]["di_personaggio"]):
    plan = plpy.prepare("SELECT COALESCE(COUNT(id), 0) AS peso FROM zaino($1)", ["integer"])
    peso = (plpy.execute(plan, [TD["new"]["di_personaggio"]]))[0]["peso"]
    plan = plpy.prepare("SELECT _COS FROM personaggio WHERE id=$1", ["integer"])
    _cos = (plpy.execute(plan, [TD["new"]["di_personaggio"]]))[0]["_cos"]
    if peso >= ceil(_cos/2):
        return "SKIP"
    else:
        return "OK"
else:
    return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_capacita_zaino BEFORE UPDATE OR INSERT ON ist_oggetto FOR EACH ROW EXECUTE PROCEDURE funzione_capacita_zaino();

--Controllo che oggetti att o dif vengano creati con attributo equip not null e viceversa per gli altri oggetti,
--e che oggetti cons vengano creati con attributo consumato not null e viceversa per gli altri oggetti
CREATE OR REPLACE FUNCTION funzione_new_att_dif()
    RETURNS TRIGGER
AS $$
plan = plpy.prepare("SELECT classe FROM tipo_oggetto WHERE id=$1", ["integer"])
classe = plpy.execute(plan, [TD["new"]["istanza_di"]])[0]["classe"]
status = "OK"
if (classe=="_ATT" or classe=="_DIF") and TD["new"]["equip"] is None:
    TD["new"]["equip"] = False
    status = "MODIFY"
elif (classe!="_ATT" and classe!="_DIF") and TD["new"]["equip"] is not None:
    TD["new"]["equip"] = None
    status = "MODIFY"
if classe=="cons" and TD["new"]["consumato"] is None:
    TD["new"]["consumato"] = False
    status = "MODIFY"
elif classe!="cons" and TD["new"]["consumato"] is not None:
    TD["new"]["consumato"] = None
    status = "MODIFY"
return status
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_new_att_dif BEFORE INSERT ON ist_oggetto FOR EACH ROW EXECUTE PROCEDURE funzione_new_att_dif();

--Controlla che un personaggio non possa equippare contemporaneamente due oggetti di attacco o difesa,
--se prova a farlo unequippa quello precedente
CREATE OR REPLACE FUNCTION funzione_equip_att_dif()
    RETURNS TRIGGER
AS $$
plan = plpy.prepare("SELECT classe FROM tipo_oggetto WHERE id=$1", ["integer"])
classe = plpy.execute(plan, [TD["new"]["istanza_di"]])[0]["classe"]
if (classe=="_ATT" or classe=="_DIF") and TD["new"]["equip"]==True:
    plan = plpy.prepare("UPDATE ist_oggetto SET equip=false WHERE di_personaggio=$1 AND (SELECT classe FROM tipo_oggetto WHERE id=ist_oggetto.istanza_di)=$2 AND equip=true", ["integer", "classe_oggetto"])
    plpy.execute(plan, [TD["new"]["di_personaggio"], classe])
    return "MODIFY"
else:
    return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_equip_att_dif BEFORE UPDATE OR INSERT ON ist_oggetto FOR EACH ROW EXECUTE PROCEDURE funzione_equip_att_dif();

--Quando il personaggio cambia stanza ogni oggetto consumabile viene eliminato
CREATE OR REPLACE FUNCTION funzione_consum_wearoff()
    RETURNS TRIGGER
AS $$
if TD["new"]["in_stanza"]!=TD["old"]["in_stanza"]:
    plan = plpy.prepare("DELETE FROM ist_oggetto WHERE di_personaggio=$1 AND istanza_di IN (SELECT id FROM tipo_oggetto WHERE classe='cons') AND consumato=true", ["integer"])
    plpy.execute(plan, [TD["new"]["id"]])
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_consum_wearoff AFTER UPDATE ON personaggio FOR EACH ROW EXECUTE PROCEDURE funzione_consum_wearoff();

--Controlla se il personaggio è morto e nel caso lo segna come tale
CREATE OR REPLACE FUNCTION funzione_morte()
    RETURNS TRIGGER
AS $$
id_pers = None
morto = False
if TD["table_name"]=="ist_oggetto" and (TD["old"]["di_personaggio"] is not None or TD["new"]["di_personaggio"] is not None):
    if TD["old"] is not None and TD["old"]["di_personaggio"] is not None:
        id_pers = TD["old"]["di_personaggio"]
    else:
        id_pers = TD["new"]["di_personaggio"]
    plan = plpy.prepare("SELECT _PFrim FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
    pfrim = plpy.execute(plan, [id_pers])[0]["_pfrim"]
    if pfrim<=0:
        plan = plpy.prepare("UPDATE personaggio SET morto=true WHERE id=$1", ["integer"])
        plpy.execute(plan, [TD["old"]["di_personaggio"]])
        morto = True
elif TD["table_name"]=="personaggio" and TD["new"]["morto"]!=True and TD["new"]["in_stanza"] is not None:
    id_pers = TD["new"]["id"]
    plan = plpy.prepare("SELECT _PFrim FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
    pfrim = plpy.execute(plan, [id_pers])[0]["_pfrim"]
    if pfrim<=0:
        plan = plpy.prepare("UPDATE personaggio SET morto=true WHERE id=$1", ["integer"])
        plpy.execute(plan, [TD["new"]["id"]])
        morto = True
if morto:
    #cancella il dungeon in cui si trova scorrendo le stanza indietro e in avanti per id fino a trovare stanze f, e cancella tutte le item del pers
    stanze = list(plpy.execute("SELECT id, finale FROM stanza ORDER BY id"))
    plan = plpy.prepare("SELECT in_stanza FROM personaggio WHERE id=$1", ["integer"])
    id_stanza_morte = plpy.execute(plan, [id_pers])[0]["in_stanza"]
    #Trovo indice della stanza_morte nella lista di tutte le stanze ottenuta
    i_stanza_morte = -1
    for s in stanze:
        if s["id"]==id_stanza_morte:
            i_stanza_morte = stanze.index(s)
    #Vado all indietro fino a incontrare una stanza finale (non la tocco)
    i_stanza = i_stanza_morte-1
    i_begin_delete = 0
    if i_stanza>=0: #se la stanza è la primissima prima può non esserci nulla
        is_finale = stanze[i_stanza]["finale"]
        while not is_finale:
            i_stanza -= 1
            is_finale = stanze[i_stanza]["finale"]
        i_begin_delete = i_stanza+1
    id_begin_delete = stanze[i_begin_delete]["id"]
    #Vado in avanti fino a incontrare una stanza finale (la includo)
    i_stanza = i_stanza_morte-1
    is_finale = False
    while not is_finale:
        i_stanza += 1
        is_finale = stanze[i_stanza]["finale"]
    id_end_delete = stanze[i_stanza]["id"]
    #Cancello tutte le stanze nel range
    plan = plpy.prepare("DELETE FROM stanza WHERE id BETWEEN $1 AND $2", ["integer", "integer"])
    plpy.execute(plan, [id_begin_delete, id_end_delete])
    #Cancello tutti gli oggetti del personaggio
    plan = plpy.prepare("DELETE FROM ist_oggetto WHERE di_personaggio=$1", ["integer"])
    plpy.execute(plan, [id_pers])

return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_item_drop_morte AFTER UPDATE ON ist_oggetto FOR EACH ROW EXECUTE PROCEDURE funzione_morte();
CREATE TRIGGER trigger_ferite_morte AFTER UPDATE ON personaggio FOR EACH ROW EXECUTE PROCEDURE funzione_morte();

--Controlla che gli spostamenti del personaggio siano permessi
CREATE OR REPLACE FUNCTION funzione_check_cambio_stanza()
    RETURNS TRIGGER
AS $$
if TD["old"]["in_stanza"] is not None and TD["new"]["in_stanza"] is not None and TD["old"]["in_stanza"]!=TD["new"]["in_stanza"]:
    plan = plpy.prepare("SELECT COALESCE(COUNT(*), 0) AS count FROM connessa WHERE stanza1=$1 AND stanza2=$2 AND visibile=true", ["integer", "integer"])
    perc = plpy.execute(plan, [TD["old"]["in_stanza"], TD["new"]["in_stanza"]])[0]["count"]
    if perc==0:
        return "SKIP"
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_check_cambio_stanza BEFORE UPDATE ON personaggio FOR EACH ROW EXECUTE PROCEDURE funzione_check_cambio_stanza();

--Quando il personaggio cambia stanza, subisce gli attacchi dai nemici presenti in quella che sta per lasciare
CREATE OR REPLACE FUNCTION funzione_attacco_cambio_stanza()
    RETURNS TRIGGER
AS $$

if TD["old"]["in_stanza"] is not None and TD["new"]["in_stanza"] is not None and TD["old"]["in_stanza"]!=TD["new"]["in_stanza"]:
    plan = plpy.prepare("SELECT * FROM attacco_nemici($1, $2)", ["integer", "integer"])
    plpy.execute(plan, [TD["old"]["id"], TD["old"]["in_stanza"]])
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_attacco_cambio_stanza AFTER UPDATE ON personaggio FOR EACH ROW EXECUTE PROCEDURE funzione_attacco_cambio_stanza();

--Quando il personaggio raccoglie un oggetto, subisce gli attacchi dei nemici nella sua stanza
CREATE OR REPLACE FUNCTION funzione_attacco_raccogli_oggetto()
    RETURNS TRIGGER
AS $$
if TD["new"]["di_personaggio"] is not None and TD["old"]["di_personaggio"] is None:
    plan = plpy.prepare("SELECT * FROM attacco_nemici($1, $2)", ["integer", "integer"])
    plpy.execute(plan, [TD["new"]["di_personaggio"], TD["old"]["in_stanza"]])
return "OK"
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_attacco_raccogli_oggetto AFTER UPDATE ON ist_oggetto FOR EACH ROW EXECUTE PROCEDURE funzione_attacco_raccogli_oggetto();
