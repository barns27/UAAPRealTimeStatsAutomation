import requests
from urllib.parse import urlparse
from bs4 import BeautifulSoup
import re
import pandas as pd

def can_scrape(url):
    parsed_url = urlparse(url)
    robots_url = f"{parsed_url.scheme}://{parsed_url.netloc}/robots.txt"
    
    response = requests.get(robots_url)
    
    if response.status_code == 200:
        if 'Disallow' in response.text:
            return (True, f"Found 'robots.txt' at {robots_url}.", response.text)
        else:
            return (False, f"No 'Disallow' rules found in 'robots.txt' at {robots_url}.", "")
    else:
        return (False, f"No 'robots.txt' found at {robots_url}.", "")
    
def scrape_matches(url):
    match_series = []
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")

        schedule_boxes = soup.find("div", id="game-schedules").find_all("a", class_="schedule-box")

        for box in schedule_boxes:
            href = box.get("href")
            match = re.search(r'/games/(\d+)/stats', href)

            if match:
                game_number = match.group(1)
                match_series.append(game_number)
    except requests.exceptions.RequestException as e:
        return(match_series,f"An error occurred: {e}")
    except AttributeError:
        return(match_series,"Could not find the specified HTML elements.")
    except Exception as e:
        return(match_series,f"An unexpected error occurred: {e}")
    
    return(sorted(match_series, key=int, reverse=True), "Success")

def scrape_sections(url, match_num):
    response = requests.get(url)
    response.raise_for_status()
    soup = BeautifulSoup(response.content, "html.parser")

    scoreboard = soup.find("div", id="scoreboard")
    game_details = soup.find("div", id="game-details")
    box_score_wrap = soup.find("div", id="box-score-wrap")
    if scoreboard:
        team_name_0, team_code_0, team_score_0, team_name_1, team_code_1, team_score_1, clock, team_0_str, team_1_str = scrape_scoreboard(scoreboard)
    if game_details:
        venue, game_date = scrape_game_details(game_details)
    if box_score_wrap:
        team_stats_df = scrape_box_score_wrap(box_score_wrap, match_num) # change stats retrieved values and add in return
    game_details_df = create_game_details_df(match_num, team_name_0, team_code_0, team_score_0, team_name_1, team_code_1, team_score_1, clock, team_0_str, team_1_str, venue, game_date)
    return game_details_df, team_stats_df

def create_game_details_df(match_num, team_name_0, team_code_0, team_score_0, team_name_1, team_code_1, team_score_1, clock, team_0_str, team_1_str, venue, game_date):
    data = {
        "match_num": [match_num],
        "team_name_0": [team_name_0],
        "team_code_0": [team_code_0],
        "team_score_0": [team_score_0],
        "team_name_1": [team_name_1],
        "team_code_1": [team_code_1],
        "team_score_1": [team_score_1],
        "clock": [clock],
        "team_0_str": [team_0_str],
        "team_1_str": [team_1_str],
        "venue": [venue],
        "game_date": [game_date]
    }
    
    game_details_df = pd.DataFrame(data)
    return game_details_df


def scrape_scoreboard(html_element):
    if html_element:
        team_0 = html_element.find("div", class_="team team-0")
        team_1 = html_element.find("div", class_="team team-1")
        clock_summary = html_element.find("div", class_="clock-summary")

        team_name_0, team_code_0, team_score_0 = scrape_team_details(team_0)
        team_name_1, team_code_1, team_score_1 = scrape_team_details(team_1)
        clock, data = scrape_clock_summary(clock_summary)
        #split data
        team_0_match_data = data[0].split(",")
        team_1_match_data = data[1].split(",")
        # Create comma-separated strings for each team
        team_0_str = ",".join(team_0_match_data)
        team_1_str = ",".join(team_1_match_data)  
    return (team_name_0, team_code_0, team_score_0, team_name_1, team_code_1, team_score_1, clock, team_0_str, team_1_str)


def scrape_clock_summary(team_element):
    if team_element:
        clock = team_element.find("div", class_="clock")
        quarter_scoring = team_element.find("div", class_="quarter-scoring")

        if clock and quarter_scoring:
            clock_text = clock.text
            quarter_scoring_table = quarter_scoring.find("table") # Find table within quarter-scoring
            if quarter_scoring_table:
                data = scrape_quarter_scoring(quarter_scoring_table)
                return (clock_text, data)

def scrape_quarter_scoring(quarter_scoring_table):
    if quarter_scoring_table:
        text = quarter_scoring_table.text

        # Find all team names (assuming they are uppercase words)
        team_matches = re.finditer(r'\b[A-Z]+\b', text)

        results = []
        for match in team_matches:
            team_name = match.group(0)
            start_index = match.end()

            # Find the next team or end of string to define the score region
            next_team_match = re.search(r'\b[A-Z]+\b', text[start_index:])
            end_index = (start_index + next_team_match.start()) if next_team_match else len(text)

            score_region = text[start_index:end_index]

            # Extract scores (numeric values)
            scores = re.findall(r'\d+', score_region)

            # Create comma-delimited string for the team
            comma_delimited_line = f"{team_name},{','.join(scores)}"
            results.append(comma_delimited_line)
    return results

def scrape_team_details(team_element):
    if team_element:
        team_name = team_element.find("div", class_="team_name")
        team_code = team_element.find("div", class_="team_code")
        team_score = team_element.find("div", class_="team_score")

        if team_name:
            team_name_span = team_name.find("span")
            team_name_text = team_name_span.text
        if team_code:
            team_code_span = team_code.find("span")
            team_code_text = team_code_span.text
        if team_score:
            team_score_span = team_score.find("span")
            team_score_text = team_score_span.text
    return (team_name_text, team_code_text, team_score_text)

def create_team_df():
    team_data = {
        "team_code": ["DLS", "UST", "ADM", "ADU", "FEU", "NU", "UE", "UP"],
        "team_name": ["De La Salle University", "University of Santo Tomas", "Ateneo de Manila University", "Adamson University", "Far Eastern University", "National University", "University of the East", "University of the Philippines"],
    }
    
    team_df = pd.DataFrame(team_data)
    return team_df

def scrape_game_details(game_details):
    if game_details:
        game_detail_divs = game_details.find_all("div", class_="game-detail")

        for detail_div in game_detail_divs:
            h6_tag = detail_div.find("h6")
            span_tag = detail_div.find("span")

            if h6_tag and span_tag:
                h6_text = h6_tag.text.strip()
                span_text = span_tag.text.strip()

                if h6_text == "Venue":
                    venue = span_text
                elif h6_text == "Game Details":
                    game_date= span_text

    return venue, game_date

def scrape_box_score_wrap(box_score_wrap, match_num):
    if box_score_wrap:
        team_codes = scrape_team_code(box_score_wrap)
        team_stats_df = scrape_all_team_stats(box_score_wrap, team_codes[0], team_codes[1], match_num)
        return team_stats_df

def scrape_all_team_stats(box_score_wrap, team_0_code, team_1_code, match_num):
    if box_score_wrap:
        boxscore_wraps = box_score_wrap.find_all("div", class_="boxscorewrap")

        if len(boxscore_wraps) >= 2:
            df_team_0 = scrape_team_stats(boxscore_wraps[0], team_0_code, match_num)
            df_team_1 = scrape_team_stats(boxscore_wraps[1], team_1_code, match_num)

            if not df_team_0.empty and not df_team_1.empty:
                return pd.concat([df_team_0, df_team_1], ignore_index=True)
            elif not df_team_0.empty:
                return df_team_0
            elif not df_team_1.empty:
                return df_team_1
            else:
                return pd.DataFrame()  # Return empty DataFrame if both are empty
        else:
            return pd.DataFrame() # Return empty if there's less than 2 boxscorewrap divs
        
def split_stats(stats):
    # Using split() and strip()
    parts = stats.split("/")
    stats_excellent = parts[0].strip()
    stats_attempts = parts[1].strip()
    return stats_excellent, stats_attempts
        
def scrape_team_stats(boxscore_wrap, team_code, match_num):
    table = boxscore_wrap.find("table", class_="box-score")
    if table:
        data = []
        rows = table.find("tbody").find_all("tr")
        for row in rows:
            cols = row.find_all("td")
            if cols:
                player_no = cols[0].text.strip()
                player_name = cols[1].text.strip()
                attack = split_stats(cols[2].text.strip())
                block = split_stats(cols[3].text.strip())
                serve = split_stats(cols[4].text.strip())
                dig = split_stats(cols[5].text.strip())
                receive = split_stats(cols[6].text.strip())
                set_val = split_stats(cols[7].text.strip())
                match_num_val = match_num

                data.append({
                    "team_code": team_code,
                    "player_no": player_no,
                    "player_name": player_name,
                    "attack_excellent": attack[0],
                    "attack_attempts": attack[1],
                    "block_excellent": block[0],
                    "block_attempts": block[1],
                    "serveexcellent": serve[0],
                    "serve_attempts": serve[1],
                    "dig_excellent": dig[0],
                    "dig_attempts": dig[1],
                    "receive_excellent": receive[0],
                    "receive_attempts": receive[1],
                    "set_excellent": set_val[0],
                    "set_attempts": set_val[1],
                    "match_num": match_num_val
                })
        return pd.DataFrame(data)
    else:
        return pd.DataFrame()  # Return empty DataFrame if table not found

def scrape_team_code(box_score_wrap):
    team_codes = []
    if box_score_wrap:
        team_divs = box_score_wrap.find_all("div", class_="team_code")

    for team_div in team_divs:
        team_code = team_div.text.strip()
        team_codes.append(team_code)

    if len(team_codes) >= 2:
        return team_codes[0], team_codes[1]
    elif len(team_codes) == 1:
        return team_codes[0], None
    else:
        return None, None