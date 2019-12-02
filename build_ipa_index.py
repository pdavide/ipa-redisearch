import os, sys
import socket
import time
import pandas as pd
import redis
from redis.sentinel import Sentinel
from redisearch import Client, TextField, TagField

def wait_for_redis():
    print('Waiting for Redis server to be ready', flush=True)
    rc = redis.Redis(password=os.environ['REDIS_PASSWORD'])
    ping = False
    while ping == False:
        try:
            ping = rc.ping()
        except:
            pass
        time.sleep(1)
    print('Redis server ready', flush=True)

def check_sentinel():
    print('Checking if this instance is sentinel managed', flush=True)
    try:
        os.environ['REDIS_SENTINEL_HOST']
    except KeyError:
        print('REDIS_SENTINEL_HOST environment variable not set', flush=True)

        return

    sentinel = Sentinel([(os.environ['REDIS_SENTINEL_HOST'], os.environ.get('REDIS_SENTINEL_PORT_NUMBER', 26379))], socket_timeout=0.1)
    sentinel_master = sentinel.discover_master(os.environ.get('REDIS_MASTER_SET', 'ipa-redisearch'))
    if sentinel_master is not None:
        hostname = socket.gethostname()
        ip_addr = socket.gethostbyname(hostname)

        if ip_addr != sentinel_master[0]: # this is a slave
            print('This is a sentinel managed slave:', flush=True)
            print('index updates are executed only on the master instance', flush=True)
            sys.exit(0)
        else:
            print('This is a sentinel managed master', flush=True)
    else:
        raise Exception('Sentinel master not available') 

def build_ipa_index():
    start_time = time.time()
    rc = redis.Redis(password=os.environ['REDIS_PASSWORD'])
    rs_client = Client('IPAIndex', conn=rc)

    try:
        rs_client.drop_index()
    except:
        pass # Index already dropped

    print('Creating index `IPAIndex`', flush=True)
    rs_client.create_index([
        TextField('ipa_code', weight=2.0),
        TextField('name', weight=2.0),
        TextField('site'),
        TextField('pec'),
        TextField('city', weight=1.4),
        TextField('county'),
        TextField('region'),
        TagField('type'),
        TextField('rtd_name'),
        TextField('rtd_pec'),
        TextField('rtd_mail'),
    ])

    print('Getting file `amministrazioni.txt` from https://www.indicepa.gov.it', flush=True)
    ipa_index_amm_url = 'https://www.indicepa.gov.it/public-services/opendata-read-service.php?dstype=FS&filename=amministrazioni.txt'
    ipa_index_amm = pd.read_csv(ipa_index_amm_url, sep='\t', dtype=str)

    print('Feeding `IPAIndex` with data from `amministrazioni.txt`', flush=True)
    for index, row in ipa_index_amm.iterrows():
        rs_client.add_document(
            row['cod_amm'],
            language='italian',
            **get_ipa_amm_item(row)
        )

    print('Getting file `ou.txt` from https://www.indicepa.gov.it', flush=True)
    ipa_index_ou_url = 'https://www.indicepa.gov.it/public-services/opendata-read-service.php?dstype=FS&filename=ou.txt'
    ipa_index_ou = pd.read_csv(ipa_index_ou_url, sep='\t', na_values=['da_indicare', 'da_indicare@x.it'], dtype=str)
    ipa_index_ou = ipa_index_ou.loc[lambda ipa_index_ou: ipa_index_ou['cod_ou'] == 'Ufficio_Transizione_Digitale']

    print('Feeding `IPAIndex` with data from `ou.txt`', flush=True)
    for index, row in ipa_index_ou.iterrows():
        rs_client.add_document(
            row['cod_amm'],
            partial=True,
            **get_ipa_rtd_item(row)
        )

    finish_time = time.time()
    print('`IPAIndex` build completed in {0} seconds'.format(round(finish_time - start_time, 2)), flush=True)

def get_ipa_amm_item(ipa_amm_row):
    ipa_amm_item = {
        'ipa_code': ipa_amm_row['cod_amm'],
        'name': ipa_amm_row['des_amm'],
        'site': ipa_amm_row['sito_istituzionale'] if ipa_amm_row.notnull()['sito_istituzionale'] else '',
        'city': ipa_amm_row['Comune'],
        'county': ipa_amm_row['Provincia'],
        'region': ipa_amm_row['Regione'],
        'type': ipa_amm_row['tipologia_istat']
    }

    pec = get_first_pec(ipa_amm_row)
    if pec:
        ipa_amm_item['pec'] = pec

    return ipa_amm_item

def get_ipa_rtd_item(ipa_ou_row):
    ipa_rtd_item = {}

    if ipa_ou_row.notnull()['nome_resp'] or ipa_ou_row.notnull()['cogn_resp']:
        ipa_rtd_item['rtd_name'] = ' '.join([
            ipa_ou_row['nome_resp'] if ipa_ou_row.notnull()['nome_resp'] else '',
            ipa_ou_row['cogn_resp'] if ipa_ou_row.notnull()['cogn_resp'] else '',
        ])

    if ipa_ou_row.notnull()['mail_resp']:
        ipa_rtd_item['rtd_mail'] = ipa_ou_row['mail_resp']

    rtd_pec = get_first_pec(ipa_ou_row)
    if rtd_pec:
        ipa_rtd_item['rtd_pec'] = rtd_pec

    return ipa_rtd_item

def get_first_pec(ipa_row):
    for x in range(1, 3):
        if ipa_row['tipo_mail' + str(x)] == 'pec':
            return ipa_row['mail' + str(x)]

    return None

wait_for_redis()
check_sentinel()
build_ipa_index()
