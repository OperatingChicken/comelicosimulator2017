INSERT INTO tipo_stanza(nome, descr, perc) VALUES ('Aula', 'Ti trovi in un laboratorio informatico abbandonato. I computer sono ancora accesi e sulla lavagna vedi diagrammi incomprensibili.', 1);
INSERT INTO tipo_stanza(nome, descr, perc) VALUES ('Bagno', 'Ti trovi in un bagno poco spazioso. I lucchetti delle porte sono rotti e tutti i WC sono fuori uso.', 0.05);
INSERT INTO tipo_stanza(nome, descr, perc) VALUES ('Cortile', 'Ti trovi in un cortile esterno con parcheggio. Alcune automobili sono state abbandonate qui.', 0.15);
INSERT INTO tipo_stanza(nome, descr, perc) VALUES ('Corridoio', 'Ti trovi in uno stretto corridoio. Sulle pareti sono appese bacheche piene di volantini.', 0.1);
INSERT INTO tipo_stanza(nome, descr, perc) VALUES ('Ufficio', 'Ti trovi in un piccolo ufficio. Appoggiati alle pareti vedi scaffali ricolmi di libri.', 0.1);

INSERT INTO nome_stanza(nome, permesso_per) VALUES ('α', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('β', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('γ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('δ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ε', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ζ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('η', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('θ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ι', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('κ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('λ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('μ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ν', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ξ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ο', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('π', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ρ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('σ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('τ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('υ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('φ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('χ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ψ', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('ω', (SELECT id FROM tipo_stanza WHERE nome='Aula'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('♂', (SELECT id FROM tipo_stanza WHERE nome='Bagno'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('♀', (SELECT id FROM tipo_stanza WHERE nome='Bagno'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅰ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅱ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅲ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅳ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅴ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅵ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅶ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅷ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅸ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅹ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅺ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('Ⅻ', (SELECT id FROM tipo_stanza WHERE nome='Cortile'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('1', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('2', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('3', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('4', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('5', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('6', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('7', (SELECT id FROM tipo_stanza WHERE nome='Corridoio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('A', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('B', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('C', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('D', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('E', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('F', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));
INSERT INTO nome_stanza(nome, permesso_per) VALUES ('G', (SELECT id FROM tipo_stanza WHERE nome='Ufficio'));

INSERT INTO modif_stanza(nome, descr) VALUES ('pulito', 'Il luogo è pulito e ordinato, pare essere rimasto nella situazione in cui è stato abbandonato.');
INSERT INTO modif_stanza(nome, descr) VALUES ('insanguinato', 'Il luogo è totalmente imbrattato di sangue e interiora.');
INSERT INTO modif_stanza(nome, descr) VALUES ('puzzolente', 'Il luogo è tappezzato di macchie verdognole, si sente un odore insopportabile.');
INSERT INTO modif_stanza(nome, descr) VALUES ('invecchiato', 'Il luogo è sporco e impolverato. Crepe e muffa lo fanno sembrare impossibilmente antico.');

INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, _danno, classe) VALUES ('Tastiera QWERTY', 'Dispositivo di input. Può essere usato come oggetto contundente.', 1, 1, 0, 0, 4, '_ATT');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, _danno, classe) VALUES ('Spranga', 'Pericoloso pezzo di metallo', 2, 0, 0, 0, 5, '_ATT');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, _danno, classe) VALUES ('Selfie stick', 'Bastoncino per autoscatti. Lungo e facile da maneggiare.', 2, 0, 1, 0, 3, '_ATT');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, _danno, classe) VALUES ('Estintore', 'Apparecchio anti-incendio. Utilizzabile per deviare attacchi o colpire con forza.', 4, 2, 0, 0, 4, '_ATT');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Computer portatile', 'Vecchio modello. Utilizzabile come scudo.', 0, 2, 0, 1, '_DIF');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Casco da motociclista', 'Perfetto per la sicurezza sulla strada. Può ingombrare.', 0, 4, -1, 2, '_DIF');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Lamiera', 'Ingombrante scarto industriale. Può parare attacchi.', -1, 3, 0, 0, '_DIF');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Nokia 3310', 'Il telefono più resistente mai prodotto. Può proteggere da proiettili e testate nucleari.', 0, 6, 0, 1, '_DIF');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF) VALUES ('Tesi di laurea', 'Poco illuminante, ma in grado di offrire uno strato di protezione aggiuntivo.', 0, 1, 0, 0);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF) VALUES ('Dispenser medico', 'Dispenser di nanobot medici, progettato per aumentare le possibilità di sopravvivenza in combattimento.', 0, 0, 0, 2);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF) VALUES ('Visore tattico', 'Dispositivo per la realtà aumentata. Utilizzato dalle forze speciali.', 0, 0, 2, 0);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF) VALUES ('Paperella di gomma', 'Può schiarire le idee.', 0, 0, 1, 0);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF) VALUES ('Berretto di lana', 'Capo di vestiario a basso livello tecnologico.', 1, 1, -1, 0);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Lattina di Mountain Dew', 'La bibita energetica più adatta ai gamer.', 1, 1, 3, 1, 'cons');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Pillole di nootropi', 'Farmaci per migliorare la performance mentale. Molte controindicazioni.', 2, 0, 5, 0, 'cons');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Iniezione di nanobot', 'Pensata per militari sacrificabili. Aumenta la performance nel combattimento.', 4, 4, 0, 2, 'cons');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe) VALUES ('Scorie radioattive', 'Liquido giallognolo di origini poco chiare. Sembra pericoloso.', 6, 4, 0, -2, 'cons');
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe, recupero_PF) VALUES ('Pacchetto di Doritos', 'Le patatine più adatte ai gamer.', 0, 0, 0, 0, 'cibo', 2);
INSERT INTO tipo_oggetto(nome, descr, _ATT, _DIF, _PER, _PF, classe, recupero_PF) VALUES ('Pacchetto di Croccantelle', 'Lo snack perfetto.', 0, 0, 0, 0, 'cibo', 2);

INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('carico di energia', 'Emana forte energia.', 2, 1, 0, 1, 0.4);
INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('carico di radiazioni', 'Ha assorbito una dose pericolosa di radiazioni.', 5, 3, 0, -2, 0.2);
INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('della percezione', 'Emana sostanze psicoattive.', 0, 0, 4, 0, 0.3);
INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('medicinale', 'Emana nanobot medici.', 0, 1, 0, 5, 0.2);
INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('resistente', 'Insolitamente robusto.', 1, 3, 0, 2, 0.4);
INSERT INTO car_oggetto(nome, descr, add_b_ATT, add_b_DIF, add_b_PER, add_b_PF, perc) VALUES ('maledetto', 'Pensato per essere inutile.', -5, -5, -5, -5, 0.1);

INSERT INTO rarita_oggetto(nome, descr, bonus, perc) VALUES ('in lega', 'Di alta qualità.', 2, 0.4);
INSERT INTO rarita_oggetto(nome, descr, bonus, perc) VALUES ('in argento', 'Molto raro.', 5, 0.2);
INSERT INTO rarita_oggetto(nome, descr, bonus, perc) VALUES ('in oro', 'Estremamente pregiato.', 10, 0.05);
INSERT INTO rarita_oggetto(nome, descr, bonus, perc) VALUES ('divino', 'Forgiato dagli dei.', 100, 0.001);


INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('Mouse', 'Dispositivo di input vivente', 1, 3, 1, 2, 1, 2, 1, 1, 0, 2);
INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('Insetto mutante', 'Creatura ingigantita dalle radiazioni', 1, 4, 2, 3, 2, 3, 1, 2, 0, 3);
INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('Zombie', 'Cadavere rianimato da un virus sconosciuto', 8, 12, 3, 8, 2, 5, 1, 3, 0, 5);
INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('Fotocopiatrice', 'Robusto macchinario cosciente', 5, 7, 10, 16, 3, 6, 1, 1, 2, 7);
INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('Androide', 'Automa dotato di intelligenza artificiale malfunzionante', 10, 15, 7, 11, 3, 7, 2, 4, 15, 30);
INSERT INTO tipo_nemico(nome, descr, min_ATT, max_ATT, min_DIF, max_DIF, min_PF, max_PF, min_danno, max_danno, min_monete, max_monete) VALUES ('P=NP', 'Problema leggendario', 20, 30, 50, 100, 20, 25, 4, 5, 1000000, 1000000);
