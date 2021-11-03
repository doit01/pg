
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
