#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <ftdi.h>

int readCallback(uint8_t *buf, int len, FTDIProgressInfo *progress, void *userdata);

int main()
{
	struct ftdi_context *ftdi = ftdi_new();
	if (ftdi == NULL)
		return EXIT_FAILURE;
	if (ftdi_usb_open(ftdi, 0x0403, 0x6014) < 0) {
		fprintf(stderr, "Couldn't open device 0403:0604: %s\n",
		    ftdi_get_error_string(ftdi));
		ftdi_free(ftdi);
		return EXIT_FAILURE;
	}
	printf("error: %d\n", ftdi_readstream(ftdi, readCallback, NULL, 2, 256));

	if (ftdi_usb_close(ftdi) < 0) {
		fprintf(stderr, "Couldn't close device 0403:0604: %s\n",
		    ftdi_get_error_string(ftdi));
		ftdi_free(ftdi);
		return EXIT_FAILURE;
	}
	ftdi_free(ftdi);
	return 0;
}

int readCallback(uint8_t *buf, int len, FTDIProgressInfo *progress, void *userdata)
{
	static int count = 0;
	count++;
	printf("%d: Received %d bytes from FTDI:\n", count, len);
	for (int i = 0; i < len; i++) {
		printf("%02x ", buf[i]);
		if (i % 16 == 15)
			printf("\n");
	}
	printf("\n\n");
	return 0;
}
