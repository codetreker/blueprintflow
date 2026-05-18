export async function greeting({ args, flags }) {
  process.stdout.write("hello, blueprintflow!\n");
  process.exit(0);
}
