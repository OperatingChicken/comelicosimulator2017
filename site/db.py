#!/usr/bin/env python3

import psycopg2
import sys
import page

class DB:
    def __init__(self, _username, _password, _db_name, _schema_name, _hostname = "localhost", debug = False):
        self.connection = psycopg2.connect(dbname = _db_name, user = _username, password = _password, host = _hostname)
        self.cursor = self.connection.cursor()
        self.cursor.execute("SET SCHEMA %s", (_schema_name,))
        self.debug = debug
    def query(self, sql, args):
        if self.debug:
            self.cursor.execute(sql, args)
            if sql.split(" ")[0].upper() == "SELECT":
                return self.cursor.fetchall()
        else:
            try:
                self.cursor.execute(sql, args)
                if sql.split(" ")[0].upper() == "SELECT":
                    return self.cursor.fetchall()
            except:
                p = page.Page("Errore!")
                p.add_paragraph("Errore!")
                p.add_text("<button type='button' onclick='window.history.back();'>Vai indietro!</button>")
                print(p.finalize())
                sys.exit(0)
    def call_function(self, func, args):
        if self.debug:
            self.cursor.callproc(func, args)
        else:
            try:
                self.cursor.callproc(func, args)
            except:
                p = page.Page("Errore!")
                p.add_paragraph("Errore!")
                p.add_text("<button type='button' onclick='window.history.back();'>Vai indietro!</button>")
                print(p.finalize())
                sys.exit(0)
    def commit(self):
        self.connection.commit()
    def finalize(self):
        self.connection.commit()
        self.cursor.close()
        self.connection.close()
