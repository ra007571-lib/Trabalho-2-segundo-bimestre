/*
TRABALHO 02 - FUNCTIONS NO POSTGRESQL (PL/pgSQL)
Aluno: João Gabriel Vilela Figueiredo
RA: 007571
Tema: Sistema de gerenciamento de oficina mecânica

Este arquivo pressupõe que as tabelas do Trabalho 01 já estejam criadas:
cliente, veiculo, funcionario, servico, ordem_servico e item_ordem_servico.
*/

-- FUNCTION 1: consulta os dados principais de uma ordem de serviço.
-- Retorna uma mensagem com cliente, veículo, funcionário e status.
CREATE OR REPLACE FUNCTION fn_resumo_ordem(p_id_ordem INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_resumo TEXT;
BEGIN
    SELECT
        'Ordem: ' || os.id_ordem ||
        ' | Cliente: ' || c.nome ||
        ' | Veículo: ' || v.marca || ' ' || v.modelo ||
        ' (' || v.placa || ')' ||
        ' | Funcionário: ' || f.nome ||
        ' | Status: ' || os.status
    INTO v_resumo
    FROM ordem_servico os
    JOIN veiculo v ON v.id_veiculo = os.id_veiculo
    JOIN cliente c ON c.id_cliente = v.id_cliente
    JOIN funcionario f ON f.id_funcionario = os.id_funcionario
    WHERE os.id_ordem = p_id_ordem;

    IF NOT FOUND THEN
        RETURN 'Ordem de serviço não encontrada.';
    END IF;

    RETURN v_resumo;
END;
$$;


-- FUNCTION 2: calcula o valor total dos itens de uma ordem.
-- COALESCE garante retorno 0.00 quando a ordem não possui itens.
CREATE OR REPLACE FUNCTION fn_total_ordem(p_id_ordem INTEGER)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(10,2);
BEGIN
    SELECT COALESCE(SUM(ios.quantidade * ios.valor_unitario), 0.00)
    INTO v_total
    FROM item_ordem_servico ios
    WHERE ios.id_ordem = p_id_ordem;

    RETURN v_total;
END;
$$;


-- FUNCTION 3: atualiza o status de uma ordem de serviço.
-- Valida os status permitidos e verifica se a ordem existe.
CREATE OR REPLACE FUNCTION fn_atualizar_status_ordem(
    p_id_ordem INTEGER,
    p_novo_status VARCHAR(20)
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_novo_status NOT IN ('Aberta', 'Em andamento', 'Concluida', 'Cancelada')
       OR p_novo_status IS NULL THEN
        RETURN 'Status inválido. Use: Aberta, Em andamento, Concluida ou Cancelada.';
    END IF;

    UPDATE ordem_servico
    SET status = p_novo_status
    WHERE id_ordem = p_id_ordem;

    IF NOT FOUND THEN
        RETURN 'Ordem de serviço não encontrada.';
    END IF;

    RETURN 'Status da ordem ' || p_id_ordem ||
           ' atualizado para: ' || p_novo_status || '.';
END;
$$;


-- EXEMPLOS DE EXECUÇÃO / VALIDAÇÃO
-- 1. Consultar o resumo da ordem de serviço número 1:
SELECT fn_resumo_ordem(1);

-- 2. Consultar o total financeiro da ordem número 1:
SELECT fn_total_ordem(1) AS total_ordem;

-- 3. Atualizar o status da ordem número 2:
SELECT fn_atualizar_status_ordem(2, 'Concluida');

-- Conferir a alteração realizada:
SELECT id_ordem, status
FROM ordem_servico
WHERE id_ordem = 2;

-- Testes de tratamento:
SELECT fn_resumo_ordem(999);                    -- ID inexistente
SELECT fn_total_ordem(999);                     -- Sem itens: retorna 0.00
SELECT fn_atualizar_status_ordem(999, 'Aberta'); -- Ordem inexistente
SELECT fn_atualizar_status_ordem(1, 'Pendente'); -- Status inválido
