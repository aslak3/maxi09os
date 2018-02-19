#ifdef __GNUC__
int main(void)  __attribute__ ((section ("main")));
#endif

void m_putstr(char *string);
void m_getstr(char *string);
