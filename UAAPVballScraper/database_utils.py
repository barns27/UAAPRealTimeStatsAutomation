import pyodbc
import configparser
from sqlalchemy import inspect  # Import inspect

def process_dbase(all_game_details, all_team_stats, team_df, players_df):
    conn = connect_to_database()
    if conn:
        drop_tables_if_exist(conn)
        create_tables(conn)
        insert_data(all_game_details, all_team_stats, team_df, players_df, conn)
        conn.close()

def drop_tables_if_exist(conn):
    cursor = conn.cursor()

    try:
        # Drop tables if they exist (in reverse order of dependencies)
        cursor.execute("IF OBJECT_ID('Team_Stats', 'U') IS NOT NULL DROP TABLE Team_Stats;")
        cursor.execute("IF OBJECT_ID('Game_Details', 'U') IS NOT NULL DROP TABLE Game_Details;")
        cursor.execute("IF OBJECT_ID('Players', 'U') IS NOT NULL DROP TABLE Players;")
        cursor.execute("IF OBJECT_ID('Teams', 'U') IS NOT NULL DROP TABLE Teams;")
        
        conn.commit()
        print("Tables dropped (if they existed)")
    except pyodbc.Error as e:
        print(f"Error dropping tables: {e}")
        conn.rollback()
    finally:
        cursor.close()

def insert_data(all_game_details, all_team_stats, team_df, players_df, conn):
    cursor = conn.cursor()

    try:# Insert data from team_df DataFrame
        for index, row in team_df.iterrows():
            cursor.execute("""
                INSERT INTO Teams (team_code, team_name)
                VALUES (?, ?)
            """, tuple(row))
        
        # Insert data from players_df DataFrame
        for index, row in players_df.iterrows():
            cursor.execute("""
                INSERT INTO Players (player_no, player_name, team_code)
                VALUES (?, ?, ?)
            """, tuple(row))
        
        # Insert data from all_game_details DataFrame
        for index, row in all_game_details.iterrows():
            cursor.execute("""
                INSERT INTO Game_Details (match_num, team_name_0, team_code_0, team_score_0, team_name_1, team_code_1, team_score_1, clock, team_0_str, team_1_str, venue, game_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, tuple(row))

        # Insert data from all_team_stats DataFrame
        for index, row in all_team_stats.iterrows():
            cursor.execute("""
                INSERT INTO Team_Stats (team_code, player_no, player_name, attack_excellent, attack_attempts, block_excellent, block_attempts, serve_excellent, serve_attempts, dig_excellent, dig_attempts, receive_excellent, receive_attempts, set_excellent, set_attempts, match_num)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, tuple(row))

        conn.commit()
        print("Data inserted successfully")
    except pyodbc.Error as e:
        print(f"Error inserting data: {e}")
        conn.rollback()
    finally:
        cursor.close()
        
def create_tables(conn):
    cursor = conn.cursor()

    try:
        # Create Teams table
        cursor.execute("""
            CREATE TABLE Teams (
                team_code VARCHAR(3) PRIMARY KEY,
                team_name VARCHAR(100) NOT NULL
            );
            PRINT 'Teams table created';
        """)

        # Create Players table
        cursor.execute("""
            CREATE TABLE Players (
            id INT PRIMARY KEY IDENTITY(1,1),
            player_no INT,
            player_name VARCHAR(100) NOT NULL,
            team_code VARCHAR(3) NOT NULL
            );
            PRINT 'Players table created';
        """)

        # Create Game_Details table
        cursor.execute("""
            CREATE TABLE Game_Details (
                match_num INT PRIMARY KEY,
                team_name_0 VARCHAR(100) NOT NULL,
                team_code_0 VARCHAR(3) NOT NULL,
                team_score_0 INT NOT NULL,
                team_name_1 VARCHAR(100) NOT NULL,
                team_code_1 VARCHAR(3) NOT NULL,
                team_score_1 INT NOT NULL,
                clock VARCHAR(50) NOT NULL,
                team_0_str VARCHAR(50) NOT NULL,
                team_1_str VARCHAR(50) NOT NULL,
                venue VARCHAR(100) NOT NULL,
                game_date VARCHAR(50) NOT NULL
            );
            PRINT 'Game_Details table created';
        """)

        # Create Team_Stats table
        cursor.execute("""
            CREATE TABLE Team_Stats (
                id INT PRIMARY KEY IDENTITY(1,1),
                match_num INT NOT NULL,
                team_code VARCHAR(3) NOT NULL,
                player_no INT NOT NULL,
                player_name VARCHAR(100) NOT NULL,
                attack_excellent INT NOT NULL,
                attack_attempts INT NOT NULL,
                block_excellent INT NOT NULL,
                block_attempts INT NOT NULL,
                serve_excellent INT NOT NULL,
                serve_attempts INT NOT NULL,
                dig_excellent INT NOT NULL,
                dig_attempts INT NOT NULL,
                receive_excellent INT NOT NULL,
                receive_attempts INT NOT NULL,
                set_excellent INT NOT NULL,
                set_attempts INT NOT NULL
            );
            PRINT 'Team_Stats table created';
        """)

        conn.commit()
        print("Tables created successfully")
    except pyodbc.Error as e:
        print(f"Error creating tables: {e}")
        conn.rollback()
    finally:
        cursor.close()
    
def connect_to_database():
    # Load configuration from config.ini
    config = configparser.ConfigParser()
    config.read('config.ini')

    try:
        conn = pyodbc.connect(
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={config['DBSETTINGS']['server']};"
            f"DATABASE={config['DBSETTINGS']['database']};"
            f"Trusted_Connection=yes;"
        )
        print("Connection to database was successful")
        return conn
    except pyodbc.Error as e:
        print("Error: Could not connect to database")
        raise e


    