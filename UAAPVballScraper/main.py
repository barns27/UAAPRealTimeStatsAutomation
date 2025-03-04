import configparser
from scraper_utils import *
import pandas as pd
from database_utils import process_dbase

config = configparser.ConfigParser()
config.read('config.ini')

main_url = config['URLSETTINGS']['main_url']
url_ext = config['URLSETTINGS']['url_ext']
url_with_ext = main_url + url_ext
match_num_max = int(config['URLSETTINGS']['match_num_max'])
match_series = []
team_df = create_team_df()

can_scrape_result, message, robots_txt = can_scrape(main_url)

if can_scrape_result:
    print(message)
    print(robots_txt)
else:
    print(message)
    match_series, message = scrape_matches(main_url)
    url_series = [url_with_ext + str(match) for match in match_series]
    match_df = pd.DataFrame({'match_num': match_series, 'url': url_series})

    for match_num in match_df['match_num']:
        url = url_with_ext + str(match_num)

        #scrape sections of pages
        game_details_df, team_stats_df = scrape_sections(url, match_num)
        
        #consolidating results
        if 'all_game_details' not in locals():
            all_game_details = game_details_df
        else:
            all_game_details = pd.concat([all_game_details, game_details_df], ignore_index=True)

        if 'all_team_stats' not in locals():
            all_team_stats = team_stats_df
        else:
            all_team_stats = pd.concat([all_team_stats, team_stats_df], ignore_index=True)

    #create players_df
    players_df = all_team_stats[['player_no', 'player_name', 'team_code']].drop_duplicates().reset_index(drop=True)

    #process dbase insertion
    process_dbase(all_game_details, all_team_stats, team_df, players_df)
    
        
        

    
    




    
        
