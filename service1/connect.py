import MySQLdb

conn = MySQLdb.connect(
      host="rc1a-rx9dq7ia7gz9tyv7.mdb.yandexcloud.net",
      port=3306,
      db="users",
      user="user1",
      passwd="password",
      ssl={'ca': '~/.mysql/root.crt'})

cur = conn.cursor()
cur.execute('CREATE TABLE table_name (id int,first_name VARCHAR(20),last_name VARCHAR(20),email VARCHAR(50),age int);')

print(cur.fetchone()[0])

conn.close()