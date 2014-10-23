from request_engine import RequestEngine
from Constants import *
import time, subprocess, signal
from sys import argv, exit
from argparse import ArgumentParser

class EtcdResolver:
	def __init__(self, hostname, host_address, etcd_address, etcd_port, etcd_directory, hosts_file, ttl):
		"""
		Initialize the service for naming the containers (hosts) in the cluster.
		"""
		self.etcd_address = etcd_address
		self.host_address = host_address
		self.request_engine = RequestEngine(etcd_address, etcd_port, etcd_directory, hostname)
		self.hostname = hostname
		self.hosts = {}
		f = open(hosts_file,'r')
		self.default_hosts = f.read()
		f.close()
		self.hosts_file = hosts_file
		self.ttl = ttl
		self.last_update = 0
		signal.signal(signal.SIGTERM, self.exception_handler)

	def run(self):
		"""
		Run to resolve names indefinitely
		"""
		try:
			while True:
				if (time.time() - self.last_update) > (0.75* self.ttl):
					while not self.update_etcd_server():
						continue
					self.update_local_names()
					self.last_update = time.time()
				time.sleep(0.75*self.ttl)
		except:
			raise
		finally:
			# write back the default configuration into the file.
			self.exception_handler()

	def update_local_names(self):
		"""
		Fetch name:address from etcd_address
		"""
		self.hosts = self.request_engine.get_hosts_from_dir('/')
		# print self.hosts
		to_write = '%s\n\n#**********************************\n\n' % self.default_hosts

		for host,ip in self.hosts.iteritems():
			to_write = to_write + ip + ' ' + host + '\n'

		f = open(self.hosts_file,'w')
		f.write(to_write)
		f.close()

	def update_etcd_server(self):
		"""
		Update the entry for the hostname to machine_address resolution.
		host_address corresponds to the address of address on which the
		container is hosted.
		"""
		return self.request_engine.set(self.hostname, self.host_address,self.ttl)

	def exception_handler(self,signal=signal.SIGTERM, frame=None):
		"""
		To handle the exceptions. If the program is closed it should remove the
		entries gracefully from hosts file, set by itself.
		"""
		f = open(self.hosts_file,'w')
		f.write(self.default_hosts)
		f.close()
		exit(0)

if __name__ == '__main__':
	# Parse the input arguments for setting the variables.
	parser = ArgumentParser('main.py')
	parser.add_argument('etcd_address', action='store',
		help='IP address of the etcd server')
	parser.add_argument('host_address', action='store',
		help='IP address of the host machine on which the container is going to run.'+
			' This is different from container local IP.')
	parser.add_argument('--etcd_port', '-p', type=int, default=ETCD_PORT, action='store',
		help='Port on which etcd server is listening. Default: 4001')
	parser.add_argument('--etcd_directory', '-d', default=ETCD_KEYS_DIRECTORY,
		action='store',
		help='Directory in etcd to store information. Default: etcd_spark')
	parser.add_argument('--hosts_file', '-f', default=HOSTS_FILE, action='store',
		help='Which file to add names of servers registered on etcd service')
	parser.add_argument('--ttl', '-t', type=int, default=TTL, action='store',
		help='Time-to-live for the entries inside etcd. In case of failure,'+
			'the entry will expire after ttl. Default: ttl=60 (seconds)')
	args = parser.parse_args(argv[1:])

	request = 'hostname'
	proc = subprocess.Popen([request], stdout=subprocess.PIPE)
	(out, err) = proc.communicate()
	hostname = out.strip()

	resolver = EtcdResolver(hostname, args.host_address, args.etcd_address,
				args.etcd_port, args.etcd_directory, args.hosts_file, args.ttl)
	resolver.run()
