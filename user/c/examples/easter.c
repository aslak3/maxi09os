#include <stdio.h>

#include <maxi09os.h>

int year, month, day;

/* This function calculates the date of Easter in year y,
   and returns the day d and month m.  The algorithm is
   taken from Knuth's "Fundamental Algorithms", where in
   turn there is acknowledgement to the Neapolitan Aloysius
   Lillius and the German Jesuit mathematician Christopher
   Clavius.  It applies for any year from 1582 to 4200. */

void dateofeaster(int y, int *d, int *m)
{
	int gold;   /* the "golden number" */
	int cent;   /* century */
	int epact;  /* the "epact" specifies full moon */
	int full;   /* date of full moon */
	int sun;    /* March (-sun)MOD 7 is a Sunday */
	int x;      /* correction for years divisible by 4
		       but not leap years, e.g. 1900 */
	int z;      /* synchronisation with moon's orbit */

	gold = y % 19 + 1;
	cent = y / 100 +1;
	x = 3 * cent / 4 - 12;
	z = (8 * cent + 5) / 25 - 5;
	sun = 5 * y / 4 - x - 10;
	if ((epact = (11 * gold + 20 + z - x) % 30) < 0)
		epact += 30;
	if (((epact == 25) && (gold > 11)) || (epact == 24))
		epact++;
	if ((full = 44 - epact) <21)
		full += 30;

	/* Easter is the "first Sunday following
	 * the first full moon which occurs on
	 * or after March 21st" */
	full += 7 - (sun + full) % 7;
	if (full > 31)
	{ 
		*m = 4;
		*d = full - 31;
	}
	else
	{ 
		*m = 3;
		*d = full;
	}
} 

int main(void)
{
	char buffer[100];

	m_putstrdefio("Dates of Easter:\r\n");

	for (year = 1980; year <= 2020; year++)
	{
		dateofeaster(year, &day, &month);
		snprintf(buffer,25,"%d %s %d\r\n", year,
			(month == 3) ? "March" : "April", day);
		m_putstrdefio(buffer);
      }

      return 0;
}
