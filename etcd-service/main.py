from request_engine import RequestEngine
from Constants import *
import time, sys, getopt, subprocess, signal


class EtcdResolver:
	def __init__(self, etcd_address, hostname, etcd_port=ETCD_PORT, etcd_directory=ETCD_KEYS_DIRECTORY, hosts_file=HOSTS_FILE, ttl=30):
		"""
		Initialize the service for naming the containers (hosts) in the cluster.
		!!! Assumption !!! The code assumes that the machine that hosts the container has same IP as the etcd_address!
		"""
		self.etcd_address = etcd_address
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
		Run to resolve names continuously
		"""
		try:
			while True:
				if (time.time() - self.last_update) > (0.5* self.ttl):
					self.update_etcd_server()
					self.update_local_names()
					self.last_update = time.time()
				time.sleep(0.5*self.ttl)
		except:
			raise
		finally:
			# write only the default configuration into the file.
			self.exception_handler()

	def update_local_names(self):
		"""
		Implement here the logic for updating the local names inside the container.
		"""
		self.hosts = self.request_engine.get_hosts_from_dir('')
		print self.hosts
		to_write = '%s\n\n#**********************************\n\n' % self.default_hosts

		for host,ip in self.hosts.iteritems():
			to_write = to_write + ip + ' ' + host + '\n'

		f = open(self.hosts_file,'w')
		f.write(to_write)
		f.close()

	def update_etcd_server(self):
		"""
		Implement here the logic for updating the etcd_server running on the machine.
		"""
		return self.request_engine.set(self.hostname, self.etcd_address,self.ttl)

	def exception_handler(self,signal=signal.SIGTERM, frame=None):
		f = open(self.hosts_file,'w')
		f.write(self.default_hosts)
		f.close()
		sys.exit(0)




if __name__ == '__main__':

	request = 'hostname'
	proc = subprocess.Popen([request], stdout=subprocess.PIPE, shell=True)
	(out, err) = proc.communicate()
	hostname = out.strip()

	help_string = 'usage:\n main.py [OPTION]\n\nOptions:\n-e\t--etcd_address <etcd_server_address>\n'
	help_string = help_string + '-h\t--help to print this message'

	argv = sys.argv
	if '-e' not in argv:
		print "You must specify the etcd_server address"
		print help_string
		sys.exit(2)

	index = argv.index('-e')
	etcd_address = argv[index+1]

	# try:
	# 	opts, args = getopt.getopt(sys.argv[1:],["e","h"], ["etcd_address","help"])
	# except getopt.GetoptError:
	# 	print 'test.py -i <inputfile> -o <outputfile>'
	# 	sys.exit(2)

	# if '-e' not in opts or '--etcd_address':
	# 	print "You must specify the etcd_server address"
	# 	print help_string
	# 	sys.exit(2)

	# for opt, arg in opts:
	# 	if opt == '-h' or opt == '--help':
	# 		print help_string
	# 		sys.exit()
	# 	elif opt in ("-e", "--etcd_address"):
	# 		etcd_address = arg

	resolver = EtcdResolver(etcd_address, hostname)
	resolver.run()
