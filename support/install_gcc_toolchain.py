import os
import os.path
import subprocess


sources = [
    { 'url':'http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2', 'hash':''},
    { 'url':'ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-4.9.2/gcc-4.9.2.tar.bz2', 'hash':'' }
]

for src in sources:
    src['filename'] = os.path.basename(src['url'])
    subprocess.run(["curl", "-C", "-", "-O", src['url']])
    print("Extracting sources...")
    subprocess.run(["tar", "xzf", src['filename']])
    print("Done")

print("Patching binutils...")
subprocess.run(["patch", "-p0", "--input=" + "binutils-2.25.patch"])
print("Done")

basedir = os.getcwd()
os.chdir(basedir + '/binutils-2.25/')

print("Compiling binutils...")
subprocess.run(["./configure", "--prefix=" + basedir, "--target=powerpc-linux-eabi"])
subprocess.run(["make"])
subprocess.run(["make", "install"])

os.mkdir(basedir + '/_build')
os.chdir(basedir + '/_build')
print("Compiling gcc...")
subprocess.run(["../gcc-4.9.2/configure", "--prefix=" + basedir, "--target=powerpc-linux-eabi", "--disable-shared", "--with-gnu-as", "--with-as=" + basedir + "/bin/powerpc-linux-eabi-as", "--disable-multilib", "--disable-threads", "--disable-tls", "--enable-target-optspace", "--enable-languages=c", "--disable-libssp", "--disable-libquadmath", "--disable-libgomp", "--disable-lto"])
subprocess.run(["make", "-j4"])
subprocess.run(["make", "install"])

print("Cleanup...")
os.chdir(basedir)
for src in sources:
    subprocess.run(["rm", src['filename']])
subprocess.run(["rm -r", "_build", "gcc-4.9.2/", "binutils-2.25/"])
print("Done")
