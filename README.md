性能监控

select * from pg_available_extensions; 开启的插件
create extension pg_stat_statements; 
select * from pg_stat_statements 
pg_stat_statements must be loaded via shared_preload_libraries 

1.修改配置参数

vi $PGDATA/postgresql.conf  

------ 

shared_preload_libraries='pg_stat_statements'

#加载pg_stat_statements模块

 

track_io_timing = on

#如果要跟踪IO消耗的时间，需要打开如上参数

track_activity_query_size = 2048

#设置单条SQL的最长长度，超过被截断显示（可选）

 

#以下配置pg_stat_statements采样参数

pg_stat_statements.max = 10000           

# 在pg_stat_statements中最多保留多少条统计信息，通过LRU算法，覆盖老的记录。  

pg_stat_statements.track = all           

# all - (所有SQL包括函数内嵌套的SQL), top - 直接执行的SQL(函数内的sql不被跟踪), none - (不跟踪)

pg_stat_statements.track_utility = off   

# 是否跟踪非DML语句 (例如DDL，DCL)，on表示跟踪, off表示不跟踪  

pg_stat_statements.save = on             

# 重启后是否保留统计信息  

------

重启数据库
————————————————
版权声明：本文为CSDN博主「瀚高PG实验室」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/pg_hgdb/article/details/79594775

pg_hba.conf 要把注释解除
该模块必须通过在postgresql.conf的shared_preload_libraries中增加pg_stat_statements来载入，因为它需要额外的共享内存。

这意味着增加或移除该模块需要一次服务器重启。


ClusterControl
监控PostgreSQL数据库性能监控手段之慢SQL、死锁
https://blog.csdn.net/sunny_day_day/article/details/119844608?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_title~default-5.no_search_link&spm=1001.2101.3001.4242.4

https://github.com/brettwooldridge/HikariCP/wiki/MBean-(JMX)-Monitoring-and-Management
https://www.jianshu.com/p/0d030fd112c5
  
   select  state,usename,datname,pid,wait_event_type,
 wait_event,substr(query ,1,50),
 xact_start, query_start,query
  from  pg_stat_activity where state <>'idle';

使用Linux监控pg步骤：
1）根据top信息，找出CPU占用率比较高的postgres进程id=XXXXX
2）通过 select pid,state,usename,datname,query from pg_stat_activity where pid= 'XXXXX’找到该进程sql，然后进行优化；
————————————————
版权声明：本文为CSDN博主「snowwang928」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qiaowan6397/article/details/101421890
  
SELECT
    procpid,
    START,
    now() - START AS lap,
    current_query
FROM
    (
        SELECT
            backendid,
            pg_stat_get_backend_pid (S.backendid) AS procpid,
            pg_stat_get_backend_activity_start (S.backendid) AS START,
            pg_stat_get_backend_activity (S.backendid) AS current_query
        FROM
            (
                SELECT
                    pg_stat_get_backend_idset () AS backendid
            ) AS S
    ) AS S
WHERE
    current_query <> '<IDLE>'
ORDER BY
    lap DESC;

　　

    
    
    SELECT pid, runtime from (select usename, pid, EXTRACT(EPOCH FROM (now() - query_start))::INT as runtime FROM pg_stat_activity) as ss where runtime > 180 order by runtime desc limit 5
