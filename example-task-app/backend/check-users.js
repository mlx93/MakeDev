const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({
  datasources: { db: { url: 'postgresql://postgres:postgres@localhost:5432/appdb' } }
});

async function main() {
  const users = await prisma.user.findMany({ take: 5, select: { id: true, email: true, name: true } });
  console.log('First 5 users:');
  users.forEach(u => console.log(`  ${u.email} (${u.name})`));
  await prisma.$disconnect();
}

main().catch(console.error);
