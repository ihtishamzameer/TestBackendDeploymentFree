using Microsoft.EntityFrameworkCore;
using Test01.Models;

namespace Test01.Context
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {

        }



        public DbSet<TestModel01> TestModel01 { get; set; }
        public DbSet<TestModel02> TestModel02 { get; set; }



        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }


    }
}