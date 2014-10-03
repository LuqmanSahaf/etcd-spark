import json
import subprocess

class RequestEngine:
	def __init__(self, etcd_address,etcd_port, etcd_directory, hostname):
		self.etcd_address = etcd_address
		self.etcd_port = etcd_port
		self.etcd_directory = etcd_directory
		self.hostname = hostname

	def get(self, key):
		"""
		!!! Assumption !!! The key being provided should contain a '/' as a prefix.
		"""
		request = 'curl -L http://%s:%s/v2/keys/%s%s' % (self.etcd_address, self.etcd_port, self.etcd_directory, key)
		proc = subprocess.Popen([request], stdout=subprocess.PIPE, shell=True)
		(out, err) = proc.communicate()
		response = json.loads(out)
		if "errorCode" in response:
			return "key_not_found"
		else:
			return response['node']['value']

	def set(self, key, value, ttl):
		request = 'curl -L -XPUT http://%s:%s/v2/keys/%s%s -d value=%s -d ttl=%i' % (self.etcd_address, self.etcd_port, self.etcd_directory, key, value, ttl)
		print request
		proc = subprocess.Popen([request], stdout=subprocess.PIPE, shell=True)
		(out, err) = proc.communicate()
		response = json.loads(out)
		if "errorCode" in response:
			return False
		else:
			return True

	def get_hosts_from_dir(self,directory):
		"""
		!!! Assumption !!! The directory being provided should contain a '/' as a prefix.
		"""
		request = 'curl -L http://%s:%s/v2/keys/%s%s?recursive=true' % (self.etcd_address, self.etcd_port, self.etcd_directory, directory)
		print request
		proc = subprocess.Popen([request], stdout=subprocess.PIPE, shell=True)
		(out, err) = proc.communicate()
		response = json.loads(out)
		# print response
		to_return = {}
		if "errorCode" in response:
			return to_return
		elif 'nodes' in response['node']:
			nodes = response['node']['nodes']
			# print nodes
			for node in nodes:
				if ('dir' in node):
					continue
				toks = node['key'].split('/')
				name = toks[len(toks)-1]
				if (name != self.hostname):
					to_return[name] = node['value']
		return to_return