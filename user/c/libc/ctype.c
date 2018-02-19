int isspace(int c)
{
	if ((char) c == ' ')
		return 1;
	else
		return 0;
}

int isdigit(int c)
{
	if ((char) c >= '0' && (char) c <= '9')
		return 1;
	else
		return 0;
}
