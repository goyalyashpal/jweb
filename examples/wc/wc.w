@*
@c
@<Header files to include@>
@<Global variables@>
@<Functions@>
@<The main program@>

@ 
@<Header files...@>=
#include <stdio.h>

@ 
@d OK 1 /* status code for successful run */
@d usage_error 1 /* status code for improper syntax */
@d cannot_open_file 2 /* status code for file access error */

@ 
@<Global variables@>=
int status = OK; /* exit status of command, initially OK */
char *prog_name; /* who we are */

@ 
@<The main...@>=
main (argc,argv)
    int argc; /* the number of arguments on the \UNIX/ command line */
    char **argv; /* the arguments themselves, an array of strings */
{
  @<Variables local to main@>;
  prog_name=argv[0];
  @<Set up option selection@>;
  @<Process all the files@>;
  @<Print the grand totals if there were multiple files @>;
  exit(status);
}

@ 
@<Var...@>=
int file_count; /* how many files there are */
char *which; /* which counts to print */
int silent = 0; /* nonzero if the silent option was selected */

@ 
@<Set up o...@>=
which = "lwc"; /* if no option is given, print all three values */
if (argc > 1 && *argv[1] == '-') {
  argv[1]++;
  if (*argv[1] == 's') silent = 1, argv[1]++;
  if (*argv[1]) which = argv[1];
  argc--; argv++;
}
file_count = argc - 1;

@ 
@<Process...@>=
argc--;
do@+{
  @<If a file is given, try to open *(++argv); continue if unsuccessful@>;
  @<Initialize pointers and counters@>;
  @<Scan file@>;
  @<Write statistics for file@>;
  @<Close file@>;
  @<Update grand totals@>; /* even if there is only one file */
}@+while (--argc > 0);

@ 
@<Variabl...@>=
int fd = 0; /* file descriptor, initialized to stdin */

@ 
@d
READ_ONLY 0 /* read access code for system open routine */

@ 
@<If a file...@>=
if (file_count > 0 && (fd = open(*(++argv), READ_ONLY)) < 0) {
  fprintf(stderr, "%s: cannot open file %s\n", prog_name, *argv);
@.cannot open file@>
  status |= cannot_open_file;
  file_count--;
  continue;
}

@ 
@<Close file@>=
close(fd);

@ 
@d
buf_size BUFSIZ /* stdio.h's BUFSIZ is chosen for efficiency*/

@ 
@<Var...@>=
char buffer[buf_size]; /* we read the input into this array */
register char *ptr; /* the first unprocessed character in buffer */
register char *buf_end; /* the first unused position in buffer */
register int c; /* current character, or number of characters just read */
int in_word; /* are we within a word? */
long word_count, line_count, char_count; /* number of words, lines, 
    and characters found in the file so far */

@ 
@<Init...@>=
ptr = buf_end = buffer;
line_count = word_count = char_count = 0;
in_word = 0;

@ 
@<Global var...@>=
long tot_word_count, tot_line_count, tot_char_count;
 /* total number of words, lines, and chars */

@ 
@<Scan...@>=
while (1) {
  @<Fill buffer if it is empty; break at end of file@>;
  c = *ptr++;
  if (c > ' ' && c < 0177) { /* visible ASCII codes */
    if (!in_word) {word_count++; in_word = 1;}
    continue;
  }
  if (c == '\n') line_count++;
  else if (c != ' ' && c != '\t') continue;
  in_word = 0; /* c is newline, space, or tab */
}

@ 
@<Fill buff...@>=
if (ptr >= buf_end) {
  ptr = buffer; c = read(fd,ptr,buf_size);
  if (c <= 0) break;
  char_count += c; buf_end = buffer + c;
}

@ 
@<Write...@>=
if (!silent) {
  wc_print(which, char_count, word_count, line_count);
  if (file_count) printf (" %s\n", *argv); /* not stdin */
  else printf ("\n"); /* stdin */
}

@ 
@<Upda...@>=
tot_line_count += line_count;
tot_word_count += word_count;
tot_char_count += char_count;

@ 
@<Print the...@>=
if (file_count > 1 || silent) {
  wc_print(which, tot_char_count, tot_word_count, tot_line_count);
  if (!file_count) printf("\n");
  else printf(" total in %d file%s\n", file_count, file_count > 1 ? "s" : "");
}

@ 
@d
print_count(n) printf("%8ld",n)

@ 
@<Fun...@>=
wc_print(which, char_count, word_count, line_count)
char *which; /* which counts to print */
long char_count, word_count, line_count; /* given totals */
{
  while (*which)
    switch (*which++) {
    case 'l': print_count(line_count); break;
    case 'w': print_count(word_count); break;
    case 'c': print_count(char_count); break;
    default: if ((status & usage_error) == 0) {
        fprintf (stderr, "\nUsage: %s [-lwc] [filename ...]\n", prog_name);
@.Usage: ...@>
        status |= usage_error;
      }
    }
}

@ 
