#!/usr/bin/env python3

import cgi
import cgitb
import db
import session
import page
import os
import sys
import hashlib
import io
import codecs

sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

cgitb.enable()
def exception_handler(a, b, c):
    print("Content-Type: text/html")
    print()
    cgitb.handler((a, b, c))
sys.excepthook = exception_handler

database = db.DB("game", "comsimgame17", "game", "game", "eip.ovh", True)

cookie = {}
if "HTTP_COOKIE" in os.environ:
    cookies = os.environ["HTTP_COOKIE"]
    cookies = cookies.split("; ")
    for c in cookies:
        c = c.split("=")
        cookie[c[0]] = c[1]
form = cgi.FieldStorage()

if "magic" in cookie:
    user_hash = cookie["magic"]
    p = page.Page("Comelico Simulator 2017")
else:
    user_hash = session.generate_random_id()
    p = page.Page("Comelico Simulator 2017", {"magic":  user_hash})

sess = session.Session(user_hash, database)

index = form.getfirst("page", "index")
if "logged" not in sess.data and index != "register":
    index = "login"

if "logged" in sess.data and sess.data["logged"] and index == "login":
    index = "index"

def redirect(where):
    global sess
    global database
    sess.update()
    database.finalize()
    print("Location: " + where)
    print()
    sys.exit(0)

def check_auth():
    if "player" not in form:
        redirect("index.py?page=error")
    player_data = database.query("SELECT creato_da FROM personaggio WHERE id = %s", (int(form.getfirst("player")),))
    if len(player_data) == 0 or player_data[0][0] != sess.data["id"]:
        redirect("index.py?page=error")

def check_parameters(tuple_params):
    for param in tuple_params:
        if param not in form:
            redirect("index.py?page=error")

if index == "login":
    if ("email" in form) and ("password" in form):
        email = form.getfirst("email")
        password = hashlib.sha512(form.getfirst("password").encode()).hexdigest()
        r = database.query("SELECT id, nome FROM utente WHERE email = %s AND pw = %s", (email, password))
        assert(len(r) <= 1)
        if len(r) == 0:
            redirect("index.py?page=login&err=1")
        else:
            sess.data["logged"] = True
            sess.data["username"] = r[0][1]
            sess.data["id"] = r[0][0]
            redirect("index.py")
    else:
        p.add_title("Login")
        p.add_form("index.py?page=login", [{"pn": "E-Mail", "n": "email", "t": "text"},
                                           {"pn": "Password", "n": "password", "t": "password"}], "Login")
        err = form.getfirst("err")
        if err == "1":
            p.add_paragraph("I dati di login inseriti sono errati!")
        p.add_button("Clicca qui per registrarti!", "index.py?page=register")
elif index == "register":
    if ("email" in form) and ("password" in form) and ("username" in form):
        if len(database.query("SELECT email FROM utente WHERE email = %s", (form.getfirst("email"),))) > 0:
            redirect("index.py?page=register&err=1")
        database.query("INSERT INTO utente(email, pw, nome) VALUES(%s, %s, %s)", (form.getfirst("email"), hashlib.sha512(form.getfirst("password").encode()).hexdigest(), form.getfirst("username")))
        redirect("index.py?page=login")
    else:
        p.add_title("Registrazione")
        p.add_form("index.py?page=register", [{"pn": "*E-Mail", "n": "email", "t": "email"},
                                              {"pn": "*Password", "n": "password", "t": "password"},
                                              {"pn": "Username", "n": "username", "t": "text"}], "Registrati")
        err = form.getfirst("err")
        if err == "1":
            p.add_paragraph("E-Mail già esistente!")
elif index == "create":
    if ("name" in form) and ("desc" in form) and ("FOR" in form) and ("INT" in form) and ("AGI" in form) and ("COS" in form):
        database.call_function("crea_personaggio", (form.getfirst("name"), form.getfirst("desc"), int(form.getfirst("FOR")), int(form.getfirst("INT")), int(form.getfirst("AGI")), int(form.getfirst("COS")), sess.data["id"]))
        redirect("index.py?page=index")
    else:
        database.call_function("tira_dadi_attr", (sess.data["id"],))
        dadi = database.query("SELECT roll1, roll2, roll3, roll4, roll5 FROM lancio_dadi_attr WHERE utente = %s", (sess.data["id"],))
        assert(len(dadi) == 1)
        p.add_title("Creazione personaggio")
        for i in range(5):
            p.add_paragraph("Dado " + str(i) + ": " + str(dadi[0][i]))
        p.add_newline()
        p.add_form("index.py?page=create", [{"pn": "*Nome", "n": "name", "t": "text"},
                                            {"pn": "Descrizione", "n": "desc", "t": "text"},
                                            {"pn": "Indice FORZA", "n": "FOR", "t": "number"},
                                            {"pn": "Indice INTELLIGENZA", "n": "INT", "t": "number"},
                                            {"pn": "Indice AGILITA", "n": "AGI", "t": "number"},
                                            {"pn": "Indice COSTITUZIONE", "n": "COS", "t": "number"}], "Crea")
elif index == "attack":
    check_auth()
    check_parameters(("player", "enemy"))
    database.call_function("attacca", (int(form.getfirst("player")), int(form.getfirst("enemy"))))
    redirect("index.py?page=play&player=" + form.getfirst("player"))
elif index == "index":
    players = database.query("SELECT id, nome, descr, morto FROM personaggio WHERE creato_da = %s", (sess.data["id"],))
    if len(players) == 0:
        redirect("index.py?page=create")
    p.add_title("Personaggi")
    for pl in players:
        p.add_button("Gioca", "index.py?page=play&amp;player=" + str(pl[0]), pl[3])
        p.add_text(" " + pl[1] + ": " + pl[2])
        if pl[3]:
            p.add_text(" (Morto)")
        p.add_newline()
    p.add_button("Crea un nuovo personaggio!", "index.py?page=create")
    p.add_newline()
    p.add_text("<button type='button' onclick='document.cookie = \"magic=;expires=Thu, 01 Jan 1970 00:00:01 GMT;\"; window.location.href = \"index.py?page=login\";'>Logout</button>")
elif index == "update_room":
    if ("player" not in form) or ("room" not in form):
        redirect("index.py?page=error")
    player_data = database.query("SELECT creato_da FROM personaggio WHERE id = %s", (int(form.getfirst("player")),))
    if len(player_data) == 0 or player_data[0][0] != sess.data["id"]:
        redirect("index.py?page=error")
    database.query("UPDATE personaggio SET in_stanza = %s WHERE id = %s", (int(form.getfirst("room")), int(form.getfirst("player"))))
    redirect("index.py?page=play&amp;player=" + form.getfirst("player"))
elif index == "play":
    def s(x):
        if x is not None:
            return str(x)
        return ""
    if "player" not in form:
        redirect("index.py?page=error")
    player_data = database.query("SELECT creato_da, in_stanza, morto, nome, descr, _for, _int, _agi, _cos, monete, pe, id FROM personaggio WHERE id = %s", (int(form.getfirst("player")),))
    if len(player_data) == 0 or player_data[0][0] != sess.data["id"]:
        redirect("index.py?page=error")
    if player_data[0][2]:
        redirect("index.py?page=index")
    if player_data[0][1] is None:
        database.call_function("inizia_partita", (int(form.getfirst("player")),))
        redirect("index.py?page=newgame&amp;player=" + form.getfirst("player"))
    room_data = database.query("SELECT id, finale, nome_tipo, descr_tipo, nome_proprio, nome_modif, descr_modif FROM stanza_view WHERE id = %s", (player_data[0][1],))
    room_adj = database.query("SELECT s.id, s.nome_tipo, s.nome_proprio FROM connessa AS c JOIN stanza_view AS s ON c.stanza2 = s.id WHERE c.stanza1 = %s AND c.visibile", (player_data[0][1],))
    player_attr = database.query("SELECT _att, _dif, _per, _pfmax, _pfrim, _danno FROM personaggio_attr_deriv WHERE id = %s", (player_data[0][-1],))
    items = database.query("SELECT nome, descr, nome_car, descr_car, nome_rarita, descr_rarita, classe, equip, _att, _dif, _per, _pf, _danno, recupero_pf, id FROM ist_oggetto_view_no_nasc WHERE in_stanza = %s", (room_data[0][0],))
    p.add_title(room_data[0][2] + " " + room_data[0][4])
    p.add_paragraph(room_data[0][3] + "<br/>" + room_data[0][6])
    if room_data[0][1]:
        p.add_paragraph("Hai trovato la strada per tornare a casa!")
        p.add_button("Termina l'avventura", "index.py?page=endgame?player=" + form.getfirst("player"))
        # TODO: fare pagina endgame
    enemies = database.query("SELECT id, nome, descr, _att, _dif, _pfmax, _pfrim, _danno FROM ist_nemico_view WHERE in_stanza = %s", (room_data[0][0],))
    if len(enemies) != 0:
        p.add_paragraph("Ci sono dei nemici:")
    for enemy in enemies:
        p.add_paragraph(enemy[1] + ": " + enemy[2])
        p.add_paragraph("ATT: " + str(enemy[3]) + " | DIF: " + str(enemy[4]) + " | PF: " + str(enemy[6]) + "/" + str(enemy[5]) + " | Danno: " + str(enemy[7]) + " ")
        p.add_button("Attacca", "index.py?page=attack&amp;player=" + form.getfirst("player") + "&amp;enemy=" + str(enemy[0]))
    p.add_paragraph("Oggetti nella stanza:")
    for item in items:
        start_desc = s(item[0]) + " " + s(item[4]) + " " + s(item[2]) + ": " + s(item[1]) + " " + s(item[3]) + " " + s(item[5])
        end_desc = "Bonus PF: " + s(item[11]) + " | ATT: " + s(item[8]) + " | DIF: " + s(item[9]) + " | PER: " + s(item[10])
        if item[6] is None:
            pass
        elif item[6] == "_ATT":
            start_desc += " (Oggetto d'attacco)"
            if item[7]:
                start_desc += " [Equipaggiato]"
            end_desc += " | Danno: " + s(item[12])
        elif item[6] == "_DIF":
            start_desc += " (Oggetto di difesa)"
            if item[7]:
                start_desc += " [Equipaggiato]"
        elif item[6] == "cons":
            pass
        elif item[6] == "cibo":
            end_desc += " | Recupero PF: " + s(item[13])
        p.add_paragraph(start_desc)
        p.add_paragraph(end_desc)
        p.add_button("Raccogli", "index.py?page=get&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
    p.add_paragraph("Da qui puoi raggiungere:")
    for room in room_adj:
        p.add_button(room[1] + " " + room[2], "index.py?page=update_room&amp;player=" + form.getfirst("player") + "&amp;room=" + str(room[0]))
        p.add_newline()
    p.add_newline()
    p.add_button("Cerca segreti (-1 PF)", "index.py?page=secret&amp;player=" + form.getfirst("player"))
    p.add_paragraph("Statistiche " + player_data[0][3] + ":")
    p.add_paragraph("PF: " + str(player_attr[0][4]) + "/" + str(player_attr[0][3]))
    p.add_paragraph("Danno: " + str(player_attr[0][5]))
    p.add_paragraph("ATT: " + str(player_attr[0][0]))
    p.add_paragraph("DIF: " + str(player_attr[0][1]))
    p.add_paragraph("PER: " + str(player_attr[0][2]))
    p.add_paragraph("FOR: " + str(player_data[0][5]))
    p.add_paragraph("INT: " + str(player_data[0][6]))
    p.add_paragraph("AGI: " + str(player_data[0][7]))
    p.add_paragraph("COS: " + str(player_data[0][8]))
    p.add_paragraph("Monete: " + str(player_data[0][9]))
    p.add_paragraph("PE: " + str(player_data[0][10]))
    p.add_button("Inventario", "index.py?page=inventory&amp;player=" + form.getfirst("player"))
    p.add_newline()
    p.add_button("Mercato", "index.py?page=marketplace&amp;player=" + form.getfirst("player"))
    p.add_newline()
    p.add_button("Torna alla selezione del personaggio", "index.py?page=index")
elif index == "secret":
    check_auth()
    database.call_function("cerca_segreti", (int(form.getfirst("player")),))
    redirect("index.py?page=play&amp;player=" + form.getfirst("player"))
elif index == "get":
    check_auth()
    check_parameters(("player", "item"))
    database.call_function("raccogli_oggetto", (int(form.getfirst("player")), int(form.getfirst("item"))))
    redirect("index.py?page=play&player=" + form.getfirst("player"))
elif index == "inventory":
    if "player" not in form:
        redirect("index.py?page=error")
    player_data = database.query("SELECT creato_da, in_stanza FROM personaggio WHERE id = %s", (int(form.getfirst("player")),))
    if len(player_data) == 0 or player_data[0][0] != sess.data["id"]:
        redirect("index.py?page=error")
    items = database.query("SELECT nome, descr, nome_car, descr_car, nome_rarita, descr_rarita, classe, equip, _att, _dif, _per, _pf, _danno, recupero_pf, id FROM zaino(%s)", (form.getfirst("player"),))
    p.add_title("Inventario")
    def s(x):
        if x is not None:
            return str(x)
        return ""
    for item in items:
        start_desc = s(item[0]) + " " + s(item[4]) + " " + s(item[2]) + ": " + s(item[1]) + " " + s(item[3]) + " " + s(item[5])
        end_desc = "Bonus PF: " + s(item[11]) + " | ATT: " + s(item[8]) + " | DIF: " + s(item[9]) + " | PER: " + s(item[10])
        if item[6] is None:
            pass
        elif item[6] == "_ATT":
            start_desc += " (Oggetto d'attacco)"
            if item[7]:
                start_desc += " [Equipaggiato]"
            end_desc += " | Danno: " + s(item[12])
        elif item[6] == "_DIF":
            start_desc += " (Oggetto di difesa)"
            if item[7]:
                start_desc += " [Equipaggiato]"
        elif item[6] == "cons":
            pass
        elif item[6] == "cibo":
            end_desc += " | Recupero PF: " + s(item[13])
        p.add_paragraph(start_desc)
        p.add_paragraph(end_desc)
        p.add_button("Getta via", "index.py?page=throw&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
        if item[6] is None:
            pass
        elif (item[6] in ("_ATT", "_DIF")) and not item[7]:
            p.add_button("Equipaggia", "index.py?page=equip&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
        elif item[6] == "cibo":
            p.add_button("Mangia", "index.py?page=eat&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
        elif item[6] == "cons":
            p.add_button("Consuma", "index.py?page=consume&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
        p.add_newline()
        p.add_form("index.py?page=sell&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]), [{"pn": "Prezzo", "n": "price", "t": "number", "min": "0"}], "Vendi")
    p.add_newline()
    p.add_button("Indietro", "index.py?page=play&amp;player=" + form.getfirst("player"))
elif index == "sell":
    check_auth()
    check_parameters(("player", "item", "price"))
    params = (int(form.getfirst("player")), int(form.getfirst("item")), int(form.getfirst("price")))
    database.call_function("vendi", params)
    redirect("index.py?page=inventory&amp;player=" + form.getfirst("player"))
elif index == "consume":
    check_auth()
    check_parameters(("player", "item"))
    database.query("UPDATE ist_oggetto SET consumato = true WHERE id = %s", (int(form.getfirst("item")),))
    redirect("index.py?page=inventory&player=" + form.getfirst("player"))
elif index == "equip":
    check_auth()
    check_parameters(("player", "item"))
    database.query("UPDATE ist_oggetto SET equip = true WHERE id = %s", (int(form.getfirst("item")),))
    redirect("index.py?page=inventory&player=" + form.getfirst("player"))
elif index == "eat":
    check_auth()
    check_parameters(("player", "item"))
    database.call_function("mangia", (int(form.getfirst("player")), int(form.getfirst("item"))))
    redirect("index.py?page=inventory&player=" + form.getfirst("player"))
elif index == "throw":
    check_auth()
    check_parameters(("player", "item"))
    database.call_function("drop_oggetto", (int(form.getfirst("player")), int(form.getfirst("item"))))
    redirect("index.py?page=inventory&player=" + form.getfirst("player"))
elif index == "newgame":
    if "player" not in form:
        redirect("index.py?page=error")
    p.add_paragraph("Ti risvegli a Comelico...")
    p.add_paragraph("Sei confuso, vedi figure misteriose aggirarsi in Comelico")
    p.add_paragraph("Non sei interessato a scoprire cosa sia successo, vuoi solo trovare la strada per tornare a casa")
    p.add_button("Inizia a giocare", "index.py?page=play&amp;player=" + form.getfirst("player"))
elif index == "marketplace":
    check_auth()
    def s(x):
        if x is not None:
            return str(x)
        return ""
    items = database.query("SELECT nome, descr, nome_car, descr_car, nome_rarita, descr_rarita, classe, equip, _att, _dif, _per, _pf, _danno, recupero_pf, id, pr_vendita, di_personaggio FROM ist_oggetto_view WHERE pr_vendita is not NULL", (None,))
    money = database.query("SELECT monete FROM personaggio WHERE id = %s", (int(form.getfirst("player")),))[0][0]
    p.add_title("Mercato")
    p.add_text("Monete disponibili: " + str(money))
    for item in items:
        start_desc = s(item[0]) + " " + s(item[4]) + " " + s(item[2]) + ": " + s(item[1]) + " " + s(item[3]) + " " + s(item[5])
        end_desc = "Bonus PF: " + s(item[11]) + " | ATT: " + s(item[8]) + " | DIF: " + s(item[9]) + " | PER: " + s(item[10])
        if item[6] is None:
            pass
        elif item[6] == "_ATT":
            start_desc += " (Oggetto d'attacco)"
            if item[7]:
                start_desc += " [Equipaggiato]"
            end_desc += " | Danno: " + s(item[12])
        elif item[6] == "_DIF":
            start_desc += " (Oggetto di difesa)"
            if item[7]:
                start_desc += " [Equipaggiato]"
        elif item[6] == "cons":
            pass
        elif item[6] == "cibo":
            end_desc += " | Recupero PF: " + s(item[13])
        p.add_paragraph(start_desc)
        p.add_paragraph(end_desc)
        p.add_paragraph("Prezzo: " + str(item[15]))
        if item[16] == int(form.getfirst("player")):
            p.add_button("Ritira", "index.py?page=withdraw&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]))
        else:
            p.add_button("Compra", "index.py?page=buy&amp;player=" + form.getfirst("player") + "&amp;item=" + str(item[14]), item[15] > money)
    p.add_newline()
    p.add_newline()
    p.add_button("Indietro", "index.py?page=play&amp;player=" + form.getfirst("player"))
elif index == "withdraw":
    check_auth()
    check_parameters(("player", "item"))
    database.query("UPDATE ist_oggetto SET pr_vendita = NULL WHERE id = %s", (int(form.getfirst("item")),))
    redirect("index.py?page=marketplace&amp;player=" + form.getfirst("player"))
elif index == "buy":
    check_auth()
    check_parameters(("player", "item"))
    database.call_function("compra", (int(form.getfirst("player")), int(form.getfirst("item"))))
    redirect("index.py?page=marketplace&amp;player=" + form.getfirst("player"))
else:
    p.add_paragraph("Errore!")
    p.add_text("<button type='button' onclick='window.history.back();'>Vai indietro!</button>")

sess.update()
database.finalize()
print(p.finalize())
