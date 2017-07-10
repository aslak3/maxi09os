void convertframe(const uint32_t data[5][256], char *name, int frame)
{
	printf("\t\t; %s frame %d ...\n\n", name, frame);

	int x, y;

	for (y = 0; y < 15; y++)
	{
		printf("\t\t; ");
		for (x = 0; x < 15; x++)
		{
			if (data[frame][(y * 16) + x])
				printf("#");
			else
				printf(" ");
		}
		printf("\n");
	}

	printf("\n");

	convert8x8(data, name, frame, 0, 0);
	convert8x8(data, name, frame, 0, 8);
	convert8x8(data, name, frame, 8, 0);
	convert8x8(data, name, frame, 8, 8);
}

void convert8x8(const uint32_t data[5][256], char *name, int frame,
	int offset_x, int offset_y)
{
	int x, y;

	for (y = offset_y; y < offset_y + 8; y++)
	{
		printf("\t\t.byte 0b");
		for (x = offset_x; x < offset_x + 8; x++)
		{
			if (data[frame][(y * 16) + x])
				printf("1");
			else
				printf("0");
		}

		printf(" ; ");

		for (x = offset_x; x < offset_x + 8; x++)
		{
			if (data[frame][(y * 16) + x])
				printf("#");
			else
				printf(" ");
		}

		printf("\n");
	}
	printf("\n");
}
