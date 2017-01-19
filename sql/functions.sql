--Rolla 5 volte 3d6 e salva tutto in una tabella di lanci temporanei
CREATE OR REPLACE FUNCTION tira_dadi_attr(utente INTEGER) RETURNS void
AS $$
import random

plan = plpy.prepare("DELETE FROM lancio_dadi_attr WHERE utente=$1", ["integer"])
plpy.execute(plan, [utente])

plan = plpy.prepare("INSERT INTO lancio_dadi_attr VALUES ($1, $2, $3, $4, $5, $6)", ["integer", "main_attribute", "main_attribute", "main_attribute", "main_attribute", "main_attribute"])
args = [utente]
for i in range(5):
    roll = 0
    for j in range(3):
        roll += random.randrange(1, 7)
    args.append(roll)
plpy.execute(plan, args)

$$ LANGUAGE plpython3u;

--Crea personaggio fornendo gli indici di 4 delle 5 rollate ottenute con la precedente funzione per associarne
--i risultati agli attributi, cancella la rollata e 
CREATE OR REPLACE FUNCTION crea_personaggio(nome TEXT, descr TEXT, rolli_for INTEGER, rolli_int INTEGER, rolli_agi INTEGER, rolli_cos INTEGER, utente INTEGER) RETURNS void
AS $$

t = [0] * 5
t[rolli_for] += 1
t[rolli_int] += 1
t[rolli_agi] += 1
t[rolli_cos] += 1
for test in t:
    if test > 1:
        raise ValueError('Errore nella selezione degli indici dei dadi')

plan = plpy.prepare("SELECT roll1, roll2, roll3, roll4, roll5 FROM lancio_dadi_attr WHERE utente=$1", ["integer"])
r = plpy.execute(plan, [utente])
plan = plpy.prepare("DELETE FROM lancio_dadi_attr WHERE utente=$1", ["integer"])
plpy.execute(plan, [utente])

roll = [0] * 5
roll[0] = r[0]["roll1"]
roll[1] = r[0]["roll2"]
roll[2] = r[0]["roll3"]
roll[3] = r[0]["roll4"]
roll[4] = r[0]["roll5"]

plan = plpy.prepare("INSERT INTO personaggio(nome, descr, _FOR, _INT, _AGI, _COS, ferite, monete, PE, prox_PE, morto, creato_da) VALUES($1, $2, $3,$4, $5, $6, 0, 0, 0, 0, false, $7)", ["text", "text", "main_attribute", "main_attribute", "main_attribute", "main_attribute", "integer"])
plpy.execute(plan, [nome, descr, roll[rolli_for], roll[rolli_int], roll[rolli_agi], roll[rolli_cos], utente])
id = (plpy.execute("SELECT last_value FROM personaggio_id_seq"))[0]["last_value"]

#Do al personaggio una tastiera e un pacchetto di doritos come item iniziali
plan = plpy.prepare("INSERT INTO ist_oggetto(di_personaggio, equip, istanza_di) VALUES ($1, true, (SELECT id FROM tipo_oggetto WHERE nome='Tastiera QWERTY'))", ["integer"])
plpy.execute(plan, [id])
plan = plpy.prepare("INSERT INTO ist_oggetto(di_personaggio, istanza_di) VALUES ($1, (SELECT id FROM tipo_oggetto WHERE nome='Pacchetto di Doritos'))", ["integer"])
plpy.execute(plan, [id])

$$ LANGUAGE plpython3u;

--Funzione che restituisce la tabella degli oggetti nello zaino di un personaggio (no in vendita, no consumati)
CREATE OR REPLACE FUNCTION zaino(id_personaggio INTEGER)
    RETURNS SETOF ist_oggetto_view
AS $$
plan = plpy.prepare("SELECT * FROM ist_oggetto_view WHERE di_personaggio=$1 AND pr_vendita IS NULL AND (consumato IS NULL OR consumato=false)", ["integer"])
r = plpy.execute(plan, [id_personaggio])
return r
$$ LANGUAGE plpython3u;

--Mangiare cibo riduce le ferite di _recuperoPF 
CREATE OR REPLACE FUNCTION mangia(id_personaggio INTEGER, id_ogg INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT recupero_PF FROM zaino($1) WHERE id=$2", ["integer", "integer"])
rec = plpy.execute(plan, [id_personaggio, id_ogg])
if rec is not None and rec[0]["recupero_pf"] is not None:
    plan = plpy.prepare("SELECT ferite FROM personaggio WHERE id=$1", ["integer"])
    ferite = plpy.execute(plan, [id_personaggio])[0]["ferite"]
    ferite -= rec[0]["recupero_pf"]
    if ferite<0:
        ferite = 0
    plan = plpy.prepare("UPDATE personaggio SET ferite=$1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [ferite, id_personaggio])
    plan = plpy.prepare("DELETE FROM ist_oggetto WHERE id=$1", ["integer"])
    plpy.execute(plan, [id_ogg])
$$ LANGUAGE plpython3u;

--Crea il grafo per una nuova partita, ritorno l'id del nodo di partenza
CREATE OR REPLACE FUNCTION crea_grafo()
    RETURNS INTEGER
AS $$

from random import randrange, random

start_node = plpy.execute("SELECT COALESCE(last_value, 0) AS last_value FROM stanza_id_seq")[0]["last_value"] + 1

#Creo le 32 stanze
tipo_stanza = [i for i in plpy.execute("SELECT id, perc FROM tipo_stanza")]
nome_stanza = plpy.execute("SELECT id, permesso_per FROM nome_stanza")
modif_stanza = plpy.execute("SELECT id FROM modif_stanza")
tipo_stanza.sort(key=lambda x: x["perc"])

stanze = []
stanze_filter = []
while len(stanze) < 32:
    tipo = tipo_stanza[-1]["id"]
    for t in tipo_stanza:
        if random()<t["perc"]:
            tipo = t["id"]
            break
    nomigiusti = [i["id"] for i in nome_stanza if i["permesso_per"]==tipo]
    nome = nomigiusti[randrange(len(nomigiusti))]
    modif = modif_stanza[randrange(len(modif_stanza))]["id"]
    s = (len(stanze)==31, tipo, nome, modif)
    s_filter = (tipo, nome)
    if s_filter not in stanze_filter:
        stanze.append(s)
        stanze_filter.append(s_filter)

for s in stanze:
    plan = plpy.prepare("INSERT INTO stanza(finale, tipo, nome, modif) VALUES ($1, $2, $3, $4)", ["boolean", "integer", "integer", "integer"])
    plpy.execute(plan, list(s))

#Creo gli archi con un algoritmo di generazione di grafi connessi
mat_adj = [[0 for j in range(32)] for i in range(32)]

for i in range(16):
    a, b = randrange(32), randrange(32)
    if a == b:
        continue
    mat_adj[a][b] = 2
    mat_adj[b][a] = 2
for i in range(1, 32):
    to_node = randrange(i)
    mat_adj[i][to_node] = 1
    mat_adj[to_node][i] = 1

for i in range(32):
    for j in range(32):
        if mat_adj[i][j] != 0:
            visibile = True
            if mat_adj[i][j] == 2:
                visibile = False
            plan = plpy.prepare("INSERT INTO connessa VALUES($1, $2, $3)", ["integer", "integer", "boolean"])
            plpy.execute(plan, [i+start_node, j+start_node, visibile])

return start_node
$$ LANGUAGE plpython3u;

--Inizia una nuova partita creando il dungeon e popolandolo (solo se non ci si trova già in una stanza e non si è morti)
CREATE OR REPLACE FUNCTION inizia_partita(id_pers INTEGER) RETURNS void
AS $$
from random import random, randrange

def geometric(p):
    n = 0
    while random() > p:
        n += 1
    return n

plan = plpy.prepare("SELECT in_stanza, morto FROM personaggio WHERE id=$1", ["integer"])
test = plpy.execute(plan, [id_pers])[0]
if test["in_stanza"] is not None or test["morto"]==True:
    raise Exception("Dungeon già generato o personaggio morto")

stanza_iniziale = plpy.execute("SELECT * FROM crea_grafo()")[0]["crea_grafo"]
plan = plpy.prepare("UPDATE personaggio SET in_stanza=$1 WHERE id=$2", ["integer", "integer"])
plpy.execute(plan, [stanza_iniziale, id_pers])

#popolo il dungeon con nemici e oggetti
plan = plpy.prepare("SELECT _ATT + _DIF + _PER + _PFmax AS difficulty FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
difficulty = plpy.execute(plan, [id_pers])[0]["difficulty"]
tipo_nemico = plpy.execute("SELECT * FROM tipo_nemico")
tipo_oggetto_cibo = plpy.execute("SELECT * FROM tipo_oggetto WHERE classe='cibo'")
tipo_oggetto_altro = plpy.execute("SELECT * FROM tipo_oggetto WHERE classe IS NULL OR classe!='cibo'")
car_oggetto = plpy.execute("SELECT * FROM car_oggetto")
rarita_oggetto = plpy.execute("SELECT * FROM rarita_oggetto")
for i in range(0, 32):
    room_difficulty = difficulty * ((30+i)/30)
    #Nessun nemico nella prima e nell ultima stanza
    if i>=1 and i<=30:
        n_nemici = geometric(0.5)
        while n_nemici>0:
            tipo_scelto = tipo_nemico[randrange(len(tipo_nemico))]
            difficulty_nemico = (tipo_scelto["min_att"] + tipo_scelto["max_att"])/2 + (tipo_scelto["min_dif"] + tipo_scelto["max_dif"])/2 + (tipo_scelto["min_pf"] + tipo_scelto["max_pf"])/2 + (tipo_scelto["min_danno"] + tipo_scelto["max_danno"])/2
            if random() < (1/3)**(difficulty_nemico/room_difficulty):
                nemico_att = randrange(tipo_scelto["min_att"], tipo_scelto["max_att"]+1)
                nemico_dif = randrange(tipo_scelto["min_dif"], tipo_scelto["max_dif"]+1)
                nemico_pf = randrange(tipo_scelto["min_pf"], tipo_scelto["max_pf"]+1)
                nemico_danno = randrange(tipo_scelto["min_danno"], tipo_scelto["max_danno"]+1)
                nemico_monete = randrange(tipo_scelto["min_monete"], tipo_scelto["max_monete"]+1)
                plan = plpy.prepare("INSERT INTO ist_nemico(_ATT, _DIF, _PFmax, _PFrim, _danno, monete, in_stanza, tipo) VALUES ($1, $2, $3, $3, $4, $5, $6, $7)", ["integer", "integer", "integer", "integer", "integer", "integer", "integer"])
                plpy.execute(plan, [nemico_att, nemico_dif, nemico_pf, nemico_danno, nemico_monete, stanza_iniziale+i, tipo_scelto["id"]])
                n_nemici -= 1
    n_oggetti = geometric(1/3)
    while n_oggetti>0:
        tipo_ogg_scelto = None
        #Con probabilità 0.3 trovo cibo
        if random() < 0.3:
            tipo_ogg_scelto = tipo_oggetto_cibo[randrange(len(tipo_oggetto_cibo))]
        else:
            tipo_ogg_scelto = tipo_oggetto_altro[randrange(len(tipo_oggetto_altro))]
        livello_tipo = tipo_ogg_scelto["_att"] + tipo_ogg_scelto["_dif"] + tipo_ogg_scelto["_per"] + tipo_ogg_scelto["_pf"] + (tipo_ogg_scelto["_danno"] if tipo_ogg_scelto["classe"]=="_att" else 0)
        if random() < (1/3)**((livello_tipo*5)/room_difficulty):
            id_car = None
            car_scelta = car_oggetto[randrange(len(car_oggetto))]
            if tipo_ogg_scelto["classe"]!="cibo" and random() < car_scelta["perc"]:
                id_car = car_scelta["id"]
            id_rar = None
            rar_scelta = rarita_oggetto[randrange(len(rarita_oggetto))]
            if tipo_ogg_scelto["classe"]!="cibo" and random() < rar_scelta["perc"]:
                id_rar = rar_scelta["id"]
            nascosto = False
            if random() < 0.5:
                nascosto = True
            plan = plpy.prepare("INSERT INTO ist_oggetto(in_stanza, nascosto, istanza_di, car, rarita) VALUES ($1, $2, $3, $4, $5)", ["integer", "boolean", "integer", "integer", "integer"])
            plpy.execute(plan, [stanza_iniziale+i, nascosto, tipo_ogg_scelto["id"], id_car, id_rar])
            n_oggetti -= 1

$$ LANGUAGE plpython3u;

--Finisce la partita, aggiunge a PE i punti exp che erano in prox_PE, cancella le 32 stanze a partire da quella in cui ci si trova
CREATE OR REPLACE FUNCTION finisci_partita(id_pers INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT prox_PE, in_stanza FROM personaggio WHERE id=$1", ["integer"])
personaggio = plpy.execute(plan, [id_pers])[0]

#controllo che la stanza sia finale
plan = plpy.prepare("SELECT finale FROM stanza WHERE id=$1", ["integer"])
is_finale = plpy.execute(plan, [personaggio["in_stanza"]])[0]["finale"]
if not is_finale:
    raise Exception("La stanza non è finale!")
    
#Aggiungo i PE al personaggio e lo tolgo dalla stanza
plan = plpy.prepare("UPDATE personaggio SET PE=PE+$1, prox_PE=0, in_stanza=NULL WHERE id=$2", ["integer", "integer"])
plpy.execute(plan, [personaggio["prox_pe"], id_pers])

#Cancello le 32 stanze all indietro a partire quella in cui si trova il personaggio
plan = plpy.prepare("DELETE FROM stanza WHERE id BETWEEN $1 AND $2", ["integer", "integer"])
plpy.execute(plan, [personaggio["in_stanza"]-31, personaggio["in_stanza"]])

$$ LANGUAGE plpython3u;

--Consuma 1 PF, rolla ed eventualmente rivela passaggi segreti/oggetti nascosti
CREATE OR REPLACE FUNCTION cerca_segreti(id_pers INTEGER) RETURNS void
AS $$
from random import randrange
#spendo 1 PF
plan = plpy.prepare("UPDATE personaggio SET ferite=ferite+1 WHERE id=$1", ["integer"])
plpy.execute(plan, [id_pers])

plan = plpy.prepare("SELECT in_stanza FROM personaggio WHERE id=$1", ["integer"])
id_stanza = plpy.execute(plan, [id_pers])[0]["in_stanza"]

plan = plpy.prepare("SELECT _PER FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
pers_per = plpy.execute(plan, [id_pers])[0]["_per"]

#rollata con successo
if randrange(1, 21) < pers_per:
    plan = plpy.prepare("SELECT id FROM ist_oggetto WHERE in_stanza=$1 AND nascosto=true", ["integer"])
    oggetti_nasc = plpy.execute(plan, [id_stanza])
    plan = plpy.prepare("SELECT stanza2 FROM connessa WHERE stanza1=$1 AND visibile=false", ["integer"])
    connessioni_nasc = plpy.execute(plan, [id_stanza])
    if len(oggetti_nasc) + len(connessioni_nasc) > 0:
        #scelgo a caso una cosa da rivelare
        selected = randrange(len(oggetti_nasc) + len(connessioni_nasc))
        if selected < len(oggetti_nasc):
            plan = plpy.prepare("UPDATE ist_oggetto SET nascosto=false WHERE id=$1", ["integer"])
            plpy.execute(plan, [oggetti_nasc[selected]["id"]])
        else:
            plan = plpy.prepare("UPDATE connessa SET visibile=true WHERE (stanza1=$1 AND stanza2=$2) OR (stanza1=$2 AND stanza2=$1)", ["integer", "integer"])
            plpy.execute(plan, [id_stanza, connessioni_nasc[selected - len(oggetti_nasc)]["stanza2"]])

#Vengo attaccato (se sono in una stanza con nemici ancora vivi)
plan = plpy.prepare("SELECT * FROM attacco_nemici($1, $2)", ["integer", "integer"])
plpy.execute(plan, [id_pers, id_stanza])

$$ LANGUAGE plpython3u;

--Raccoglie un oggetto (controlla che si possa raccogliere e setta nascosto a NULL)
CREATE OR REPLACE FUNCTION raccogli_oggetto(id_pers INTEGER, id_ogg INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT in_stanza FROM personaggio WHERE id=$1", ["integer"])
check_pers = plpy.execute(plan, [id_pers])[0]
plan = plpy.prepare("SELECT in_stanza, nascosto FROM ist_oggetto WHERE id=$1", ["integer"])
check_ogg = plpy.execute(plan, [id_ogg])[0]
if check_pers["in_stanza"]!=check_ogg["in_stanza"] or check_ogg["nascosto"]==True:
    raise Exception("Raccoglimento oggetto non permesso!")

plan = plpy.prepare("UPDATE ist_oggetto SET nascosto=NULL, in_stanza=NULL, di_personaggio=$1 WHERE id=$2", ["integer", "integer"])
plpy.execute(plan, [id_pers, id_ogg])
$$ LANGUAGE plpython3u;

--Fai cadere un oggetto (controlla che tu lo abbia e setta nascosto a false)
CREATE OR REPLACE FUNCTION drop_oggetto(id_pers INTEGER, id_ogg INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT di_personaggio FROM ist_oggetto WHERE id=$1", ["integer"])
check_ogg = plpy.execute(plan, [id_ogg])[0]["di_personaggio"]
if check_ogg!=id_pers:
    raise Exception("Drop non permesso!")

plan = plpy.prepare("SELECT in_stanza FROM personaggio WHERE id=$1", ["integer"])
id_stanza = plpy.execute(plan, [id_pers])[0]["in_stanza"]
plan = plpy.prepare("UPDATE ist_oggetto SET nascosto=false, in_stanza=$1, di_personaggio=NULL WHERE id=$2", ["integer", "integer"])
plpy.execute(plan, [id_stanza, id_ogg])
$$ LANGUAGE plpython3u;

--Rolla il danno di un attacco fornendo _att e _danno dell'attaccante e _dif del difensore
CREATE OR REPLACE FUNCTION rolla_attacco(_att INTEGER, _danno INTEGER, _dif INTEGER)
    RETURNS INTEGER
AS $$
from random import randrange

if _att - _dif + randrange(1, 21) >= 12:
    return _danno
else:
    return 0
$$ LANGUAGE plpython3u;

--Attacchi dei nemici, chiamati o triggerati quando si svolgono azioni (attaccare, spostarsi, raccogliere, cercare)
CREATE OR REPLACE FUNCTION attacco_nemici(id_pers INTEGER, id_stanza INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT _ATT, _danno FROM ist_nemico WHERE in_stanza=$1", ["integer"])
nemici = plpy.execute(plan, [id_stanza])
plan = plpy.prepare("SELECT _DIF FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
personaggio = plpy.execute(plan, [id_pers])[0]

for n in nemici:
    plan = plpy.prepare("SELECT * FROM rolla_attacco($1, $2, $3)", ["integer", "integer", "integer"])
    danno_attacco = plpy.execute(plan, [n["_att"], n["_danno"], personaggio["_dif"]])[0]["rolla_attacco"]
    plan = plpy.prepare("UPDATE personaggio SET ferite = ferite + $1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [danno_attacco, id_pers])

$$ LANGUAGE plpython3u;

--Attacca un nemico (subendo gli attacchi nello stesso turno)
CREATE OR REPLACE FUNCTION attacca(id_pers INTEGER, id_nemico INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT _ATT, _DIF, _PFmax, _PFrim, _danno, monete, in_stanza FROM ist_nemico WHERE id=$1", ["integer"])
nemico = plpy.execute(plan, [id_nemico])[0]

#Controllo che non stia attaccando un nemico non raggiungibile
plan = plpy.prepare("SELECT in_stanza FROM personaggio WHERE id=$1", ["integer"])
id_stanza_pers = plpy.execute(plan, [id_pers])[0]["in_stanza"]
if id_stanza_pers != nemico["in_stanza"]:
    raise Exception("Nemico nella stanza sbagliata")

#Attacchi dei nemici
plan = plpy.prepare("SELECT * FROM attacco_nemici($1, $2)", ["integer", "integer"])
plpy.execute(plan, [id_pers, id_stanza_pers])

#Attacco
plan = plpy.prepare("SELECT _ATT, _danno FROM personaggio_attr_deriv WHERE id=$1", ["integer"])
personaggio = plpy.execute(plan, [id_pers])[0]
plan = plpy.prepare("SELECT * FROM rolla_attacco($1, $2, $3)", ["integer", "integer", "integer"])
danno_attacco = plpy.execute(plan, [personaggio["_att"], personaggio["_danno"], nemico["_dif"]])[0]["rolla_attacco"]

pfrim_nemico = nemico["_pfrim"] - danno_attacco
if pfrim_nemico > 0:
    plan = plpy.prepare("UPDATE ist_nemico SET _PFrim = $1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [pfrim_nemico, id_nemico])
else:
    #Nemico ucciso, prendo le monete, i punti esperienza (calcolati dalla somma dei suoi attributi x100) e lo elimino
    plan = plpy.prepare("UPDATE personaggio SET monete=monete+$1, prox_PE=prox_PE+$2 WHERE id=$3", ["integer", "integer", "integer"])
    plpy.execute(plan, [nemico["monete"], (nemico["_att"]+nemico["_dif"]+nemico["_pfmax"]+nemico["_danno"])*100, id_pers])
    plan = plpy.prepare("DELETE FROM ist_nemico WHERE id=$1", ["integer"])
    plpy.execute(plan, [id_nemico])
$$ LANGUAGE plpython3u;

--Compra oggetto messo in vendita: controlla se l'oggetto è disponibile e se si hanno le monete, poi effettua la transazione
CREATE OR REPLACE FUNCTION compra(id_pers_buyer INTEGER, id_ogg INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT monete FROM personaggio WHERE id=$1", ["integer"])
buyer_monete = plpy.execute(plan, [id_pers_buyer])[0]["monete"]
plan = plpy.prepare("SELECT di_personaggio, pr_vendita FROM ist_oggetto WHERE id=$1", ["integer"])
oggetto_vend = plpy.execute(plan, [id_ogg])[0]

if oggetto_vend["pr_vendita"] is None or buyer_monete < oggetto_vend["pr_vendita"]:
    raise Exception("Errore! Articolo non in vendita o prezzo troppo alto")

#Uso una transazione per garantire il trasferimento corretto dell oggetto e dei fondi
with plpy.subtransaction():
    plan = plpy.prepare("UPDATE ist_oggetto SET pr_vendita=NULL, di_personaggio=$1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [id_pers_buyer, id_ogg])
    plan = plpy.prepare("UPDATE personaggio SET monete=monete+$1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [oggetto_vend["pr_vendita"], oggetto_vend["di_personaggio"]])
    plan = plpy.prepare("UPDATE personaggio SET monete=monete-$1 WHERE id=$2", ["integer", "integer"])
    plpy.execute(plan, [oggetto_vend["pr_vendita"], id_pers_buyer])
$$ LANGUAGE plpython3u;

--Vendi oggetto dall'inventario: controlla che sia tuo e setta equip a false se c'è
CREATE OR REPLACE FUNCTION vendi(id_pers INTEGER, id_ogg INTEGER, prezzo INTEGER) RETURNS void
AS $$
plan = plpy.prepare("SELECT di_personaggio, equip FROM ist_oggetto WHERE id=$1", ["integer"])
oggetto = plpy.execute(plan, [id_ogg])[0]
if oggetto["di_personaggio"]!=id_pers:
    raise Exception("Non puoi vendere oggetti non tuoi!")

newequip = None
if oggetto["equip"] is not None:
    newequip = False

plan = plpy.prepare("UPDATE ist_oggetto SET equip=$1, pr_vendita=$2 WHERE id=$3", ["boolean", "integer", "integer"])
plpy.execute(plan, [newequip, prezzo, id_ogg])
$$ LANGUAGE plpython3u;
