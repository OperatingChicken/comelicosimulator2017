#!/usr/bin/env python3

import tempfile
import os
import hashlib
import json
import db

def generate_random_id():
    return hashlib.sha256(os.urandom(256)).hexdigest()

class Session:
    def __init__(self, _id, _db):
        self.id = _id;
        self.database = _db
        if not self._already_exists():
            self.data = {}
        else:
            self.data = self.database.query("SELECT valore FROM sessione WHERE chiave = %s", (self.id,))[0][0]
    def update(self):
        if self._already_exists():
            self.database.query("UPDATE sessione SET valore = %s WHERE chiave = %s", (json.dumps(self.data), self.id))
        else:
            self.database.query("INSERT INTO sessione VALUES(%s, %s)", (self.id, json.dumps(self.data)))
        self.database.commit()
    def _already_exists(self):
        return len(self.database.query("SELECT valore FROM sessione WHERE chiave = %s", (self.id,))) > 0
