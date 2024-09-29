# Natural Text to HTML Converter
## Project Overview
The aim of this project is to develop a software system that can convert a simple natural text format into valid HTML code, while adhering to specific formatting rules.

## Project Objectives
### 1. Lexical Analysis (Lex File):
Develop a Lex file for the lexical analysis of the text input and generate the corresponding tokens.
### 2. Syntactic Analysis (Yacc Parser):
Implement a Yacc parser for the syntactic analysis of the input text and the generation of an internal data structure.
### 3. Text Formatting Rules:
Define text formatting rules, including the recognition of:
  * Titles
  * Lists
  * Colored buttons
  * Formatted text (italic, bold, italic-bold)
### 4. HTML Code Generation:
Convert the internal data structure into valid HTML code based on the specified formatting rules.
## Project Structure
The project is organized as follows:
  * Lex File: Handles lexical analysis and token generation.
  * Yacc Parser: Manages syntactic parsing and data structure creation.
  * Formatting Rules: Applies formatting and structures the text for proper HTML generation.
  * HTML Generator: Transforms the internal data into valid HTML output.
## Technologies Used
  * Lex: For lexical analysis.
  * Yacc (Yet Another Compiler-Compiler): For parsing and syntactic analysis.
## Usage
To run this project, you need:
  * A Lex/Yacc development environment.
  * Input a text file with the natural text format that will be analyzed.
  * The program will output the corresponding HTML code based on the formatting rules.
