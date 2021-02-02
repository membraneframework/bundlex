#include <assert.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#ifndef _REENTRANT
#define _REENTRANT // For some reason __erl_errno is undefined unless _REENTRANT
                   // is defined
#endif
#include <example_lib/example_lib_cnode.h>
#include <ei.h>
#include <ei_connect.h>

double foo(double a, double b) {
    return add(a, b);
}

int listen_sock(int *listen_fd, int *port) {
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  assert(fd > 0);

  int opt_on = 1;
  assert(setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt_on, sizeof(opt_on)) == 0);

  struct sockaddr_in addr;
  unsigned int addr_size = sizeof(addr);
  addr.sin_family = AF_INET;
  addr.sin_port = htons(0);
  addr.sin_addr.s_addr = htonl(INADDR_ANY);

  assert(bind(fd, (struct sockaddr *)&addr, addr_size) == 0);
  assert(getsockname(fd, (struct sockaddr *)&addr, &addr_size) == 0);
  *port = (int)ntohs(addr.sin_port);
  const int queue_size = 5;
  assert(listen(fd, queue_size) == 0);

  *listen_fd = fd;
  return 0;
}

int handle_message(int ei_fd, char *node_name, erlang_msg emsg,
                   ei_x_buff *in_buf) {
  ei_x_buff out_buf;
  ei_x_new_with_version(&out_buf);
  int decode_idx = 0;
  int version;
  char fun[255];
  int arity;

  assert(ei_decode_version(in_buf->buff, &decode_idx, &version) == 0);
  ei_decode_tuple_header(in_buf->buff, &decode_idx, &arity);
  assert(ei_decode_atom(in_buf->buff, &decode_idx, fun) == 0);

  double res = 0.0;
  if (!strcmp(fun, "foo")) {
    double a, b;
    assert(ei_decode_double(in_buf->buff, &decode_idx, &a) == 0);
    assert(ei_decode_double(in_buf->buff, &decode_idx, &b) == 0);
    res = foo(a, b);

    assert(ei_x_encode_tuple_header(&out_buf, 2) == 0);
    assert(ei_x_encode_atom(&out_buf, node_name) == 0);
    assert(ei_x_encode_double(&out_buf, res) == 0);
    ei_send(ei_fd, &emsg.from, out_buf.buff, out_buf.index);
  }

  ei_x_free(&out_buf);
  return 0;
}

int receive(int ei_fd, char *node_name) {
  ei_x_buff in_buf;
  ei_x_new(&in_buf);
  erlang_msg emsg;
  int res = 0;
  switch (ei_xreceive_msg_tmo(ei_fd, &emsg, &in_buf, 5000)) {
  case ERL_TICK:
    break;
  case ERL_ERROR:
    if (erl_errno == ETIMEDOUT) {
      fprintf(stderr, "Timeout. Message not received.");
    }
    res = erl_errno;
    break;
  default:
    if (emsg.msgtype == ERL_REG_SEND &&
        handle_message(ei_fd, node_name, emsg, &in_buf)) {
      res = -1;
    }
    break;
  }

  ei_x_free(&in_buf);
  return res;
}

int validate_args(int argc, char **argv) {
  assert(argc == 6);
  for (int i = 1; i < argc; i++) {
    assert(strlen(argv[i]) < 255);
  }
  return 0;
}


int main(int argc, char **argv) {
  assert(validate_args(argc, argv) == 0);

  char host_name[256];
  strcpy(host_name, argv[1]);
  char alive_name[256];
  strcpy(alive_name, argv[2]);
  char node_name[256];
  strcpy(node_name, argv[3]);
  char cookie[256];
  if(*argv[4] != '\0') 
    strcpy(cookie, argv[4]);
  else
    strcpy(cookie, getenv("BUNDLEX_ERLANG_COOKIE"));
  short creation = (short)atoi(argv[5]);

  int listen_fd;
  int port;
  assert(listen_sock(&listen_fd, &port) == 0);

  ei_cnode ec;
  struct in_addr addr;
  addr.s_addr = inet_addr("127.0.0.1");
  assert(ei_connect_xinit(&ec, host_name, alive_name, node_name, &addr, cookie,
                       creation) >= 0);
  assert(ei_publish(&ec, port) != -1);
  printf("ready\r\n");
  fflush(stdout);

  ErlConnect conn;
  int ei_fd = ei_accept_tmo(&ec, listen_fd, &conn, 5000);
  assert(ei_fd != ERL_ERROR);

  int res = receive(ei_fd, node_name);

  close(listen_fd);
  close(ei_fd);
  return res;
}
