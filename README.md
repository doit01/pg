citus对sql有限制 分布表到各个节点，但没有解决高可用。
Patroni 3.0 是citus推荐的高可用方案。
pgpool 负责，监控。
最终方案。单库主备，分区表。

pg_stat_statements
https://blog.csdn.net/ouyongke/article/details/125791388


pg流复制 逻辑复制
优先用流复制，因为逻辑复制不支持DML 新增表

plugin
timescaledb：时序数据库
zhparser、pg_jieba、pg_scws、friso：中文分词

pg_trgm、pg_bigm(没有3个分词限制)、pgroonga：模糊查询

pg_similarity、cube：相似查询

pg_query_state：后台工作情况


高可用
pg_keeper：仅用于将standby切换为master, 或者自动降级.
patroni
pgpool-II
stolon
repmgr
pacemaker + corosync
PAF( PostgreSQL Automatic Failover )
pg_auto_failover
可观察性
    client backends
        pg_stat_ssl, pg_blocking_pids(), pg_stat_activity
    query planning
        EXPLAIN, pg_stat_statements
    query execution
        pg_stat_activity, pg_stat_statements, pg_stat_progress_create_index, pg_stat_progress_cluster, pg_prepared_xacts, pg_stat_kcache, pg_locks
    indexes usage
        pg_stat_all_indexes
    tables usage
        pg_stat_all_tables

=====================全文检索
select count(*) from pg_stat_activity;
show max_connections
-- 
SELECT 'fat & rat'::tsquery; -- 'fat' & 'rat'


SELECT to_tsquery('Fat:ab & Cats'); -- 'fat':AB & 'cat'

SELECT to_tsquery('english', 'The & Fat & Rats'); --'fat' & 'rat'

SELECT to_tsquery('chinese', 'The & Fat & Rats');
SELECT 'fat & rat'::tsquery;



--- .tsvector

SELECT 'The Fat Rats Fat 中国 李白 中国'::tsvector; -- 按空格分词 分词的顺序是按照长短和字母排序的, 自动去掉分词中重复的词条

SELECT 'a:1 fat:2 cat:3 sat:4 on:5 a:6 mat:7 and:8 ate:9 a:10 fat:11 rat:12'::tsvector --词条位置常量也可以放到词汇中

SELECT 'a:1A fat:2B,4C cat:5D'::tsvector;  --拥有位置的词汇甚至可以用一个权来标记，反映文档结构，这个权可以是A，B，C或D。默认的是D，因此输出中不会出现  1表示位置，A表示权重

SELECT to_tsvector('english', 'The Fat Rats');--to_tsvector函数对这些单词进行规范化处理, 罗列出词条并连同它们文档中的位置


--- 基本文本匹配
–全文检索基于匹配算子@@，当一个tsvector(理解成文章)匹配到一个tsquery（理解成用户输入）时，则返回true, tsvector和tsquery两种数据类型可以任意排序。

SELECT 'a fat cat sat on a mat and ate a fat rat'::tsvector @@ 'cat & rat'::tsquery AS RESULT;
SELECT 'cat & rat'::tsquery @@ 'a fat cat sat on a mat and ate a fat rat'::tsvector AS RESULT;

SELECT 'fat & cow & mat & rat'::tsquery @@ 'a fat cat sat on a mat and ate a fat rat'::tsvector AS RESULT;

SELECT 'a fat cat sat on a mat and ate a fat rat'::tsvector @@  'fat & cow & mat & rat'::tsquery  AS RESULT;


– to_tsvector和to_tsquery标准化处理


– to_tsvector和to_tsquery标准化处理

SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat & rat') AS RESULT;
SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat&rat') AS RESULT;   -- & means and 
SELECT to_tsvector('fat cats ate fat rats') @@ to_tsquery('fat |cow') AS RESULT;  -- | means  or 

4.分词器
–查看所有分词器
\dF
–查看默认分词器

show default_text_search_config;

 default_text_search_config 
----------------------------
 pg_catalog.english
(1 row)


表和索引

CREATE SCHEMA tsearch;
CREATE TABLE tsearch.pgweb(id int, body text, title text, last_mod_date date);
INSERT INTO tsearch.pgweb VALUES(1, 'China, officially the People''s Republic of China(PRC), located in Asia, is the world''s most populous state.', 'China', '2010-1-1');
INSERT INTO tsearch.pgweb VALUES(2, 'America is a rock band, formed in England in 1970 by multi-instrumentalists Dewey Bunnell, Dan Peek, and Gerry Beckley.', 'America', '2010-1-1');
INSERT INTO tsearch.pgweb VALUES(3, 'England is a country that is part of the United Kingdom. It shares land borders with Scotland to the north and Wales to the west.', 'England','2010-1-1');

–- 将body字段中包含america的行打印出来

SELECT id, body, title FROM tsearch.pgweb WHERE to_tsvector(body) @@ to_tsquery('america');

-– 检索出在title或者body字段中包含china和asia的行
SELECT * FROM tsearch.pgweb WHERE to_tsvector(title || ' ' || body) @@ to_tsquery('china & asia');

–为了加速文本搜索，可以创建GIN索引(指定english配置来解析和规范化字符串)

CREATE INDEX pgweb_idx_1 ON tsearch.pgweb USING gin(to_tsvector('english', body));

–连接列的索引
CREATE INDEX pgweb_idx_3 ON tsearch.pgweb USING gin(to_tsvector('english', title || ' ' || body));

–查看索引定义

\d+ tsearch.pgweb

                            Table "tsearch.pgweb"
    Column     |  Type   | Modifiers | Storage  | Stats target | Description 
---------------+---------+-----------+----------+--------------+-------------
 id            | integer |           | plain    |              | 
 body          | text    |           | extended |              | 
 title         | text    |           | extended |              | 
 last_mod_date | date    |           | plain    |              | 
Indexes:
    "pgweb_idx_1" gin (to_tsvector('english'::regconfig, body)) TABLESPACE pg_default
    "pgweb_idx_3" gin (to_tsvector('english'::regconfig, (title || ' '::text) || body)) TABLESPACE pg_default
Has OIDs: no
Options: orientation=row, compression=no

6.清理数据

drop schema tsearch cascade;

课程作业

1.用tsvector @@ tsquery和tsquery @@ tsvector完成两个基本文本匹配

select to_tsvector('The quick brown fox jumps over the lazy dog') @@ to_tsquery('fox & dog');

select to_tsquery('fox & cow') @@ to_tsvector('The quick brown fox jumps over the lazy dog');

2.创建表且至少有两个字段的类型为 text类型，在创建索引前进行全文检索

CREATE SCHEMA tsearch;
CREATE TABLE tsearch.pgweb(id int, body text, title text, last_mod_date date);
INSERT INTO tsearch.pgweb VALUES(1, 'China, officially the People''s Republic of China(PRC), located in Asia, is the world''s most populous state.', 'China', '2010-1-1');
INSERT INTO tsearch.pgweb VALUES(2, 'America is a rock band, formed in England in 1970 by multi-instrumentalists Dewey Bunnell, Dan Peek, and Gerry Beckley.', 'America', '2010-1-1');
INSERT INTO tsearch.pgweb VALUES(3, 'England is a country that is part of the United Kingdom. It shares land borders with Scotland to the north and Wales to the west.', 'England','2010-1-1');

SELECT id, body, title FROM tsearch.pgweb WHERE to_tsvector(body) @@ to_tsquery('england');
SELECT title FROM tsearch.pgweb WHERE to_tsquery('england & kingdom') @@ to_tsvector(title || ' ' || body);

这里的title || ' ' || body，中间的空格字符串不能省略，不然会搜不到，这个我就不是很明白了。

3.创建GIN索引

CREATE INDEX pgweb_idx_1 ON tsearch.pgweb USING gin(to_tsvector('english', body));

4.清理数据

drop schema tsearch cascade;


show client_encoding;
=====================全文检索



====高可用 pg pool
https://www.postgresql.org/
https://www.pgpool.net/docs/latest/en/html/tutorial-watchdog-intro.html#TUTORIAL-WATCHDOG-COORDINATING-NODES

https://blog.csdn.net/zxfmamama/article/details/121008549?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-4.pc_relevant_aa&spm=1001.2101.3001.4242.3&utm_relevant_index=7

=====监控
最耗IO SQL，单次调用最耗IO SQL TOP 5

select userid::regrole, dbid, query from pg_stat_statements order by (blk_read_time+blk_write_time)/calls desc limit 5;  

总最耗IO SQL TOP 5

select userid::regrole, dbid, query from pg_stat_statements order by (blk_read_time+blk_write_time) desc limit 5;  

最耗时 SQL，单次调用最耗时 SQL TOP 5

select userid::regrole, dbid, query from pg_stat_statements order by mean_time desc limit 5;  

总最耗时 SQL TOP 5

select userid::regrole, dbid, query from pg_stat_statements order by total_time desc limit 5;  


响应时间抖动最严重 SQL

select userid::regrole, dbid, query from pg_stat_statements order by stddev_time desc limit 5;  

最耗共享内存 SQL

select userid::regrole, dbid, query from pg_stat_statements order by (shared_blks_hit+shared_blks_dirtied) desc limit 5;  

最耗临时空间 SQL

select userid::regrole, dbid, query from pg_stat_statements order by temp_blks_written desc limit 5;  
————————————————
版权声明：本文为CSDN博主「瀚高PG实验室」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/pg_hgdb/article/details/79594775


https://postgresql.blog.csdn.net/article/details/79594775?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-1.pc_relevant_default&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-1.pc_relevant_default&utm_relevant_index=1
当pg_stat_statements被载入时，它会跟踪该服务器 的所有数据库的统计信息。

该模块提供了一个视图 pg_stat_statements以及函数pg_stat_statements_reset 和pg_stat_statements用于访问和操纵这些统计信息。

这些视图 和函数不是全局可用的，但是可以用CREATE EXTENSION pg_stat_statements 为特定数据库启用它们
1.修改配置参数

vi $PGDATA/postgresql.conf  

------ 

shared_preload_libraries='pg_stat_statements'

#加载pg_stat_statements模块

 

track_io_timing = on

#如果要跟踪IO消耗的时间，需要打开如上参数

track_activity_query_size = 2048

#设置单条SQL的最长长度，超过被截断显示（可选）
————————————————
版权声明：本文为CSDN博主「瀚高PG实验室」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/pg_hgdb/article/details/79594775


查询pg全部设置
select 
"name", 
"setting", 
"unit", 
"category", 
"short_desc", 
"extra_desc", 
"context", 
"vartype", 
"source", 
"min_val", 
"max_val", 
"enumvals", 
"boot_val", 
"reset_val", 
"sourcefile", 
"sourceline", 
"pending_restart"
from pg_settings ps
-- where ps.name like '%statement_timeout%' 



=====
SELECT created_date , jde_cost_number ,atch_number
from ebr_basic_entity ebe  where jde_cost_number like '%42%' and position('42' in trim(leading '42' from jde_cost_number)) >1
and substring(jde_cost_number from 1 for 2)= '42' and created_date >'2022-01-01 00:37:08'


性能监控
查询长事务sql
select * from pg_stat_activity where state <> 'idle' 
and (backend_xid is not null or backend_xmin is not null)  and now()-xact_start > interval'1 sec'::interval;


select * from pg_available_extensions; 开启的插件
create extension pg_stat_statements; 
select * from pg_stat_statements 
pg_stat_statements must be loaded via shared_preload_libraries 

1.修改配置参数

vi $PGDATA/postgresql.conf  
在data/postgresql.conf中，进行配置：
shared_preload_libraries = 'pg_stat_statements'，表示要在启动时导入pg_stat_statements 动态库。
pg_stat_statements.max = 1000，表示监控的语句最多为1000句。
pg_stat_statements.track = top # ，表示不监控嵌套的sql语句。all - (所有SQL包括函数内嵌套的SQL), top - 直接执行的SQL(函数内的sql不被跟踪), none - (不跟踪)
pg_stat_statements.track_utility = true，表示对 INSERT/UPDATE/DELETE/SELECT 之外的sql动作也作监控。
pg_stat_statements.save = true，  on 表示当postgresql停止时，把信息存入磁盘文件以备下次启动时再使用。

重新启动 postgresql，创建sql语句：

create extension pg_stat_statements;

查询哪些sql语句执行效率慢：

    SELECT  query, calls, total_time, (total_time/calls) as average ,rows, 
            100.0 * shared_blks_hit /nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent 
    FROM    pg_stat_statements 
    ORDER   BY average DESC LIMIT 10;

#加载pg_stat_statements模块
track_io_timing = on
#如果要跟踪IO消耗的时间，需要打开如上参数
track_activity_query_size = 2048
#设置单条SQL的最长长度，超过被截断显示（可选）
#以下配置pg_stat_statements采样参数
pg_stat_statements.max = 10000           
# 在pg_stat_statements中最多保留多少条统计信息，通过LRU算法，覆盖老的记录。  
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
