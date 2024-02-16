import pandas as pd
import json
from bs4 import BeautifulSoup

# Load the CSV file into a DataFrame
df = pd.read_csv('FAQ_contents_1_31_2024.csv')

# Remove HTML markup from the 'response' column
df['response'] = df['response'].apply(lambda x: BeautifulSoup(x, 'html.parser').get_text())

# Combine the 'question' and 'response' columns into a new 'text' column
#df['text'] = df['question'] + ": " + df['response']
#df['text'] = "<s>[INST] " + df['question'] + " [/INST]</s>[INST] " + df['response'] + " [/INST]"
df['text'] = "<s>[INST] " + df['question'] + " [/INST]</s> " + df['response']

# Select only the 'text' column and convert it to JSON
json_data = df['text'].apply(lambda x: {"text": x}).to_json(orient='records', lines=True)
# Select only the 'text' column and convert it to JSON with the desired format
#json_data = df['text'].apply(lambda x: {"text": f'{{"text":"{x}"}}'}).to_json(orient='records', lines=True)

json_data = json_data.replace('\/', '/')

# Print the JSON data
print(json_data)

# Save the JSON data to a file
with open('train.jsonl', 'w') as f:
    f.write(json_data)

with open('valid.jsonl', 'w') as f:
    f.write(json_data)

with open('test.jsonl', 'w') as f:
    f.write(json_data)
