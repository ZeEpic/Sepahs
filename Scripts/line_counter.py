import os

total_lines = 0
total_files = 0
total_characters = 0
temp_lines = 0
total_real_chars = 0
lines = {}

##for i in os.listdir():
##	print(i)
##	temp_lines = 0
##	if i.find(".") != -1:
##		total_files += 1
##		with open(i, "r") as f:
##			for line in f:
##				total_lines += 1
##				total_characters += len(line)
##				temp_lines += 1
##				for char in line:
##					if not char in [" ", "\n", "\t"]:
##						total_real_chars += 1
##		lines[i] = temp_lines


for i in os.listdir():
	total_files += 1
	temp_lines = 0
	with open(i, "r") as f:
		for line in f:
			total_lines += 1
			total_characters += len(line)
			temp_lines += 1
			for char in line:
				if not char in [" ", "\n", "\t"]:
					total_real_chars += 1
	lines[i] = temp_lines

max_lines = max(lines.values())
for k,v in lines.items():
	if v == max_lines:
		max_line_name = k
		del lines[k]
		break
second_lines = max(lines.values())
for k,v in lines.items():
	if v == second_lines:
		second_line_name = k
		del lines[k]
		break
third_lines = max(lines.values())
for k,v in lines.items():
	if v == third_lines:
		third_line_name = k
		break

print("Total files:", total_files)
print("Total lines:", total_lines)
print("Total characters:", total_characters)
print("Total characters with out spaces:", total_real_chars)
print("Average characters per line:", round(total_characters/total_lines))
print("Average lines per file:", round(total_lines/total_files))
print("Top 3 most lines in a file:\n\t1.", max_lines, "in the file called '"+max_line_name+"'")
print(" \t2.", second_lines, "in the file called '"+second_line_name+"'")
print(" \t3.", third_lines, "in the file called '"+third_line_name+"'")
